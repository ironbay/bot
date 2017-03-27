defmodule Bot.Skill.Slack do
	use Bot.Skill
	alias Delta.Dynamic

	def init(bot, [team, token]) do
		{:ok, pid} = Slack.Bot.start_link(Bot.Skill.SlackRTM, %{bot: bot}, token)
		{:ok, %{
			rtm: pid,
			team: team,
			token: token,
		}}
	end

	def handle_cast({"bot.message", text, context = %{team: team}}, _bot, state = %{team: team}) do
		Slack.Web.Chat.post_message(context.channel, text, %{
			token: state.token,
			as_user: true,
			channel: context.channel,
			thread_ts: context.thread,
		})
		{:noreply, state}
	end

	def handle_cast({"bot.reply", text, context = %{team: team}}, _bot, state = %{team: team}) do
		Slack.Web.Chat.post_message(context.channel, text, %{
			token: state.token,
			as_user: true,
			channel: context.channel,
			thread_ts: context.key,
		})
		{:noreply, state}
	end

	def handle_cast({"bot.image", body = %{url: url}, context = %{team: team}}, _bot, state = %{team: team}) do
		Slack.Web.Chat.post_message(context.channel, "", %{
			token: state.token,
			as_user: true,
			thread_ts: context.thread,
			attachments: [
				%{
					fallback: url,
					pretext: Map.get(body, :title),
					image_url: url,
				}
			] |> JSX.encode!
		})
		{:noreply, state}
	end

	def handle_cast({"slack.message", message, context = %{team: team}}, bot, state = %{team: team}) do
		text =
			message.text
			|> String.replace("<", "")
			|> String.replace(">", "")
		Bot.cast(bot, "chat.message", %{ text: text }, context)
		{:noreply, state}
	end
end

defmodule Bot.Skill.SlackRTM do
	use Slack

	def handle_connect(slack = %{
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
			key: message.ts,
			team: state.team,
			channel: message.channel,
			sender: sender,
			thread: Map.get(message, :thread_ts, ""),
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
