defmodule Bot.Skill.Hello do
	use Bot.Skill
	alias Bot.Skill.Regex

	def init(bot, _) do
		Regex.add(bot, "chat.hello", "^hello$")
		Regex.add(bot, "chat.good", "^good$")
		Regex.add(bot, "chat.bad", "^bad$")
		{:ok, %{}}
	end


	defcast("chat.hello", _body, context, state) do
		Bot.cast(bot, "bot.message", "Hey there how are you?", context)
		wait do
			{"chat.good", _, context} -> 
				cast("bot.message", "That's great! Glad to hear that")
			{"chat.bad", _, context} ->
				cast("bot.message", "That sucks I'm sorry to hear that'")
		end
		# question "Hey there how are you?" do
		# 	wait "chat.good" do
		# 		cast("bot.message", "That's great to hear!")
		# 	end
		# 	wait "chat.bad" do
		# 		question "Sorry to hear that. What happened?" do
		# 			wait "chat.message" do
		# 				cast("bot.message", "Damn that does suck")
		# 			end
		# 		end
		# 	end
		# end
		{:noreply, state}
	end
end
