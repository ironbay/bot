defmodule Bot.Skill do
	defmacro __using__(_opts) do
		quote do
			import Bot.Skill
			@before_compile Bot.Skill

			@casts MapSet.new
			@calls MapSet.new
			
			def init(_bot, args) do
				{:ok, %{}}
			end

			defoverridable [init: 2]
		end
	end

	defmacro wait(do: block) do
		actions =
			block
			|> Enum.map(fn {_, _, [[line | _] | _]} ->
				{_, _, [action | _]} = line
				action
			end)
			|> MapSet.new
			|> Enum.to_list
		quote do
			Task.start_link fn ->
				bot = var!(bot)
				context = var!(context)
				case Bot.wait(bot, unquote(actions), context) do
					unquote(block)
				end
			end
		end
	end

	defmacro cast(action, body, context \\ nil) do
		quote do
			bot = var!(bot)
			context = unquote(context) || var!(context)
			Bot.cast(var!(bot), unquote(action), unquote(body), context)
		end
	end

	defmacro defcast(action, body, context, state, do: block) do
		filter = filter(action)
		quote do
			@casts MapSet.put(@casts, unquote(filter))
			def handle_cast({unquote(action), unquote(body), unquote(context)}, bot, unquote(state)) do
				var!(bot) = bot
				unquote(block)
			end
		end
	end

	defmacro defcall(action, body, context, state, do: block) do
		quote do
			@calls MapSet.put(@calls, unquote(action))
			def handle_call({unquote(action), unquote(body), unquote(context)}, bot, unquote(state)), do: unquote(block)
		end
	end

	defmacro __before_compile__(env) do
		quote do
			def casts, do: @casts
			def calls, do: @calls

			def handle_call(event, bot, state), do: {:reply, nil, state}
			def handle_cast(event, bot, state), do: {:noreply, state}
			def handle_info(event, bot, state), do: {:noreply, state}
		end
	end

	defp filter(action) when is_binary(action), do: action
	defp filter({_, _, _}), do: "*"
end