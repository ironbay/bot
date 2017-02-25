defmodule Bot do

	def cast(bot, action, body \\ %{}, context \\ %{}) do
		msg = {action, body, context}
		IO.inspect(msg)
		bot
		|> pending_group
		|> :syn.publish(msg)

		bot
		|> skills
		|> Enum.each(&GenServer.cast(&1, msg))
	end

	def call(bot, action, body \\ %{}, context \\ %{}) do
		msg = {action, body, context}
		self = self()
		bot
		|> skills
		|> Stream.filter(&(&1 !== self))
		|> Task.async_stream(&GenServer.call(&1, msg))
		|> Stream.map(fn {:ok, value} -> value end)
		|> Stream.take_while(&(&1 != nil))
		|> Stream.take(1)
		|> Enum.at(0)
	end

	def skills(bot) do
		bot
		|> skill_group
		|> :syn.get_members
	end

	def skill_group(bot) do
		{bot, __MODULE__}
	end

	def pending_group(bot) do
		{bot, __MODULE__, :pending}
	end

	def start_skill(bot, skill, args \\ []) do
		bot
		|> Bot.Skill.Supervisor.start_child(skill, args)
	end

	def add_skill(bot, pid) do
		bot
		|> Bot.skill_group
		|> :syn.join(pid)
	end

	def wait_async(bot, filter, actions, payload \\ []) do
		self = self()
		Task.start_link(fn ->
			result = wait(bot, filter, actions)
			send(self, {:response, result, payload})
		end)
	end

	def wait(bot, filter, actions) do
		# Clear existing registrations on context
		bot
		|> pending_group
		|> :syn.publish({:new, filter})

		# Join pending
		bot
		|> pending_group
		|> :syn.join(self())


		# Event loop
		result = loop(filter, MapSet.new(actions))

		# Leave pending group
		bot
		|> pending_group
		|> :syn.leave(self())

		# Process result
		case result do
			:stop -> Process.exit(self(), :normal)
			_ -> result
		end
	end

	defp loop(filter, actions) do
		receive do
			{:new, ^filter} ->
				:stop
			event = {action, _body, context} ->
				cond do
					compare(filter, context) && MapSet.member?(actions, action) -> event
					true -> loop(filter, actions)
				end

		end
	end

	defp compare(child, parent) do
		child == Map.take(parent, Map.keys(child))
	end

	def test do
	end
end
