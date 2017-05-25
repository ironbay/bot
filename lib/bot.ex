defmodule Bot do

	def cast(bot, action, body \\ %{}, context \\ %{}) do
		msg = {action, body, context}

		bot
		|> skill_group(:pending, action)
		|> publish(msg)

		bot
		|> skills(:cast, action)
		|> Enum.each(&GenServer.cast(&1, msg))
	end

	def call(bot, action, body \\ %{}, context \\ %{}) do
		msg = {action, body, context}
		self = self()
		bot
		|> skills(:call, action)
		|> Stream.filter(&(&1 !== self))
		|> Task.async_stream(&GenServer.call(&1, msg))
		|> Stream.map(fn {:ok, value} -> value end)
		|> Stream.take_while(&(&1 != nil))
		|> Stream.take(1)
		|> Enum.at(0)
	end

	def skills(bot, type, action) do
		bot
		|> skill_group(type, action)
		|> members
	end

	def skill_group(bot, type, action) do
		{bot, __MODULE__, type, action}
	end

	defp members(group) do
		{:ok, result} =
            group
			|> :lasp_pg.members
		result |> :sets.to_list
	end

	defp publish(group, msg) do
		group
        |> members
		|> Enum.each(fn pid -> send(pid, msg) end)
	end

	def start_skill(bot, skill, args \\ []) do
		bot
		|> Bot.Skill.Supervisor.start_child(skill, args)
	end

	def subscribe(bot, pid, type, action) do
		bot
		|> skill_group(type, action)
		|> :lasp_pg.join(pid)
	end

	def wait_async(bot, filter, actions, payload \\ []) do
		self = self()
		Task.start_link(fn ->
			result = wait(bot, filter, actions)
			send(self, {:response, result, payload})
		end)
	end

	def wait(bot, actions, filter) do
		filter = Map.delete(filter, :key)

		actions
		|> Enum.each(fn action ->
			bot
			|> skill_group(:pending, action)
			|> publish({:new, filter})
			
			subscribe(bot, self(), :pending, action)
		end)

		# Event loop
		result = loop(filter)

		# Leave pending group
		actions
		|> Enum.each(fn action ->
			bot
			|> skill_group(:pending, action)
			|> :lasp_pg.leave(self())
		end)

		# Process result
		case result do
			:stop -> Process.exit(self(), :normal)
			_ -> result
		end
	end

	defp loop(filter) do
		receive do
			{:new, ^filter} ->
				IO.inspect("CLOSED")
				:stop
			event = {action, _body, context} ->
				cond do
					compare(filter, context) -> event
					true -> loop(filter)
				end

		end
	end

	defp compare(child, parent) do
		child == Map.take(parent, Map.keys(child))
	end

	def test do
	end
end
