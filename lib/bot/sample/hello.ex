defmodule Bot.Skill.Hello do
	use Bot.Skill

	def init(bot, _) do
		Bot.call(bot, "regex.add", %{
			pattern: "^hello$",
			event: "chat.hello",
		})
		Bot.call(bot, "regex.add", %{
			pattern: "^good$",
			event: "chat.good",
		})
		Bot.call(bot, "regex.add", %{
			pattern: "^bad$",
			event: "chat.bad",
		})
		{:ok, %{}}
	end

	def handle_cast({"chat.hello", _body, context}, bot, state) do
		Bot.cast(bot, "bot.message", "Hey there, how are you?", context)
		{:wait, ["chat.good", "chat.bad"], state}
	end

	def handle_response({"chat.good", _, context}, _payload, bot, state) do
		Bot.cast(bot, "bot.message", "That's great to hear!", context)
		{:noreply, state}
	end

	def handle_response({"chat.bad", _, context}, _payload, bot, state) do
		Bot.cast(bot, "bot.message", "Sorry to hear that :(", context)
		{:noreply, state}
	end
end
