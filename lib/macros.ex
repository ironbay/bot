defmodule Bot.Macros do
	defmacro wait(actions) do
		quote do
			Bot.wait(var!(bot), var!(context), unquote(actions))
		end
	end

	defmacro question(msg, callback) do
		[do: {_, _, listeners}] = callback
		actions =
			case listeners do
				[action, [do: _]] -> [action]
				_ ->
					listeners
					|> Stream.map(fn {_, _, [action, _]} -> action end)
					|> Enum.to_list
			end
		quote do
			Bot.Macros.cast("bot.message", unquote(msg))
			Task.start_link fn ->
				{action, body, context} = Bot.wait(var!(bot), var!(context), unquote(actions))
				var!(next_action) = action
				var!(body) = body
				unquote(callback)
			end
		end
	end

	defmacro wait(action, callback) do
		quote do
			if unquote(action) == var!(next_action), do: unquote(callback)
		end
	end

	defmacro test(input) do
		quote do

		end
	end

	defmacro cast(action, body, context \\ nil) do
		quote do
			context = unquote(context) || var!(context)
			Bot.cast(var!(bot), unquote(action), unquote(body), context)
		end
	end
end
