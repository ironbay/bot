defmodule Bot.Skill do
	defmacro __using__(_) do
		quote do
			@before_compile Bot.Skill
		end
	end

	defmacro __before_compile__(_env) do
		quote do
			def init(_bot, _args) do
				{:ok, %{}}
			end

			def handle_cast_async(_event, _bot, _data) do
				:ok
			end

			def handle_cast(_event, _bot, state) do
				{:noreply, state}
			end

			def handle_call(_event, _bot, state) do
				{:reply, nil, state}
			end

			def handle_info(_event, _bot, _data) do
				nil
			end
		end
	end
end

defmodule Bot.Skill.Sample do
	use Bot.Skill

	def handle_cast(msg = {"hello", _body, _context}, _bot, state) do
		{:ok, state}
	end
end
