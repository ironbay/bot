defmodule Bot.Skill.Delay do
	use GenServer

	def start_link(bot, skill, args) do
		GenServer.start_link(__MODULE__, [bot, skill, args])
	end

	def init([bot, skill, args]) do
		{:noreply, state} = handle_info(:start, [bot, skill, args])
		{:ok, state}
	end

	def handle_info(:start, state = [bot, skill, args]) do
		{:ok, pid} = Bot.Skill.Wrapper.start(bot, skill, args)
		Process.monitor(pid)
		{:noreply, state}
	end


	def handle_info({:DOWN, _, _, _, _}, state) do
		Process.send_after(self(), :start, 5000)
		{:noreply, state}
	end
end
