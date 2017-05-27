defmodule Bot.Skill.Wrapper do
	use GenServer

	def start(bot, skill, args) do
		GenServer.start(__MODULE__, [bot, skill, args])
	end

	def start_link(bot, skill, args) do
		GenServer.start_link(__MODULE__, [bot, skill, args])
	end

	def init([bot, skill, args]) do
		send(self(), :start)
		skill.casts
		|> Enum.map(&Bot.subscribe(bot, self(), :cast, &1))
		skill.calls
		|> Enum.map(&Bot.subscribe(bot, self(), :call, &1))
		{:ok, %{
			bot: bot,
			data: %{},
			args: args,
			skill: skill,
		}}
	end

	def handle_info(:start, state) do
		IO.puts("Initializing #{state.skill}")
		{:ok, data} = state.skill.init(state.bot, state.args)
		{:noreply, %{
			state |
			data: data
		}}
	end

	def handle_info({:response, event = {_action, _body, context}, payload}, state) do
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

	def handle_cast(event = {_action, _body, context}, state) do
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

	def handle_call(msg = {_action, _body, _context}, _from, state) do
		{:reply, value, data} = state.skill.handle_call(msg, state.bot, state.data)
		{:reply, value, %{
			state |
			data: data
		}}
	end

end
