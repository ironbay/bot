defmodule Bot.Skill.Slack do
	use Bot.Skill
	alias Delta.Dynamic

	def init(bot, [team, token]) do
		{:ok, pid} = Slack.Bot.start_link(Bot.Skill.SlackRTM, %{bot: bot}, token)
		{:ok, %{
			rtm: pid,
			team: team,
		}}
	end

	def handle_cast({"bot.message", text, context = %{team: team}}, _bot, state = %{team: team}) do
		send(state.rtm, {:message, text, context.channel})
		{:noreply, state}
	end

	def handle_cast({"slack.message", message, context}, bot, state) do
		Bot.cast(bot, "chat.message", %{ text: message.text }, context)
		{:noreply, state}
	end
end

defmodule Bot.Skill.SlackRTM do
	use Slack

	def handle_connect(%{
		me: %{
			id: id
		},
		team: %{
			domain: team,
		}
	}, state) do
		{
			:ok,
			state
			|> Map.put(:me, id)
			|> Map.put(:team, team)
		}
	end

	def handle_info({:message, text, channel}, slack, state) do
		send_message(text, channel, slack)
		{:ok, state}
	end

	def handle_info(_, _, state) do
		{:ok, state}
	end

	def handle_event(message = %{type: "message", user: sender}, _slack, state = %{me: me}) when sender != me do
		Bot.cast(state.bot, "slack.message", message, %{
			team: state.team,
			channel: message.channel,
			sender: sender,
		})
		{:ok, state}
	end

	def handle_event(message = %{type: "reaction_added", user: sender, item: %{channel: channel}}, _slack, state = %{me: me}) when sender != me do
		Bot.cast(state.bot, "slack.reaction.add", message, %{
			team: state.team,
			channel: channel,
			sender: sender,
		})
		{:ok, state}
	end

	def handle_event(message = %{type: "reaction_removed", user: sender, item: %{channel: channel}}, _slack, state = %{me: me}) when sender != me do
		Bot.cast(state.bot, "slack.reaction.remove", message, %{
			team: state.team,
			channel: channel,
			sender: sender,
		})
		{:ok, state}
	end


	def handle_event(_msg, _slack, state) do
		{:ok, state}
	end
end
