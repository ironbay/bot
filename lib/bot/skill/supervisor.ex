defmodule Bot.Skill.Supervisor do
	use Supervisor
	@name __MODULE__

	def start_link do
		Supervisor.start_link(@name, [], name: @name)
	end

	def init(_) do
		children = [
			worker(Bot.Skill.Delay, [], restart: :permanent),
		]
		opts = [strategy: :simple_one_for_one]
		supervise(children, opts)
	end

	def start_child(bot, skill, args) do
		Supervisor.start_child(@name, [bot, skill, args])
	end
end
