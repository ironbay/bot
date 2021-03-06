defmodule Bot.Application do
	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	@moduledoc false

	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false

		children = [
			supervisor(Bot.Skill.Supervisor, []),
		]

		opts = [strategy: :one_for_one, name: Bot.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
