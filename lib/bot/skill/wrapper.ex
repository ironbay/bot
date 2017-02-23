defmodule Bot.Skill.Wrapper do
	use GenServer

	def start_link(bot, skill, args) do
		GenServer.start_link(__MODULE__, [bot, skill, args])
	end

	def init([bot, skill, args]) do
		Bot.add_skill(bot, self())
		IO.puts("Initializing #{skill}")
		{:ok, data} = skill.init(bot, args)
		{:ok, %{
			bot: bot,
			data: data,
			skill: skill,
		}}
	end

	def handle_info({:response, event = {action, body, context}, payload}, state) do
		data =
			case state.skill.handle_response(event, payload, state.bot, state.data) do
				{:noreply, data} -> data
				{:wait, actions, data} ->
					Bot.wait_async(state.bot, context, actions)
					data
				{:wait, actions, payload, data} ->
					Bot.wait_async(state.bot, context, actions, payload)
					data
			end
		{:noreply, %{
			state |
			data: data
		}}
	end

	def handle_info(msg, state) do
		case state.skill.handle_info(msg, state.bot, state.data) do
			{:noreply, data} ->
				{:noreply, %{
					state |
					data: data,
				}}
			{:stop, reason, data} ->
				{:stop, reason, %{
					state |
					data: data,
				}}
		end
	end

	def handle_cast(event = {action, body, context}, state) do
		Task.start_link(fn -> handle_cast_async(event, state) end)

		data =
			case state.skill.handle_cast(event, state.bot, state.data) do
				{:noreply, data} -> data
				{:wait, actions, data} ->
					Bot.wait_async(state.bot, context, actions)
					data
				{:wait, actions, payload, data} ->
					Bot.wait_async(state.bot, context, actions, payload)
					data
			end
		{:noreply, %{
			state |
			data: data
		}}
	end

	def handle_cast_async(msg, state) do
		state.skill.handle_cast_async(msg, state.bot, state.data)
	end

	def handle_call(msg = {action, body, context}, _from, state) do
		{:reply, value, data} = state.skill.handle_call(msg, state.bot, state.data)
		{:reply, value, %{
			state |
			data: data
		}}
	end

	defp response?(filter, context, action, actions) do
		compare(filter, context) && MapSet.member?(actions, action)
	end

	defp compare(child, parent) do
		child == Map.take(parent, Map.keys(child))
	end

end
