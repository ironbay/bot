defmodule Bot.Skill.Regex do
	use Bot.Skill
	alias Delta.Dynamic

	def init(bot, _args) do
		{:ok, %{}}
	end

	def handle_call({"regex.add", item = %{pattern: pattern, event: event}, _context}, bot, state) do
		compiled = Regex.compile! "(?i)#{pattern}"
		{:reply, :ok, Map.put(state, compiled, event)}
	end

	def handle_cast({"chat.message", %{text: text}, context}, bot, state) do
		state
		|> Enum.each(fn {regex, event} ->
			case Regex.named_captures(regex, text) do
				nil -> :skip
				results ->
					parsed =
						results
						|> Enum.into(%{})
						|> Dynamic.keys_to_atoms
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
end
