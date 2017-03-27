defmodule Bot.Skill.Hello do
	use Bot.Skill
	import Bot.Macros

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
		question "Hey there how are you?" do
			wait "chat.good" do
				cast("bot.message", "That's great to hear!")
			end
			wait "chat.bad" do
				question "Sorry to hear that. What happened?" do
					wait "chat.message" do
						cast("bot.message", "Damn that does suck")
					end
				end
			end
		end
		{:noreply, state}
	end
end
