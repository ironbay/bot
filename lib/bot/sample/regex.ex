defmodule Bot.Skill.Regex do
	use Bot.Skill

	def init(bot, _args) do
		{:ok, %{}}
	end

	defcall("regex.add", item = %{pattern: pattern, event: event}, _context, state) do
		compiled = Regex.compile! "(?i)#{pattern}"
		{:reply, :ok, Map.put(state, compiled, event)}
	end

	defcast("chat.message", %{text: text}, context, state) do
		state
		|> Enum.each(fn {regex, event} ->
			case Regex.named_captures(regex, text) do
				nil -> :skip
				results ->
					parsed =
						results
						|> Enum.into(%{})
						|> atom_keys
						|> Map.put(:raw, text)
					Bot.cast(bot, event, parsed, context)
			end
		end)
		{:noreply, state}
	end

	def add(bot, event, pattern) do
		Bot.call(bot, "regex.add", %{
			pattern: pattern,
			event: event,
		})
	end

	defp atom_keys(input), do: for {key, val} <- input, into: %{}, do: {String.to_atom(key), val}

end
