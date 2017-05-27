defmodule Bot.Group.PG do
	def join(group, pid) do
		case :pg2.join(group, pid) do
			{:error, {:no_such_group, _}} ->
				:pg2.create(group)
				join(group, pid)
			result -> result
		end
	end

	def leave(group, pid) do
		:pg2.leave(group, pid)
	end

	def members(group) do
		case :pg2.get_members(group) do
			{:error, {:no_such_group, _}} -> []
			result -> result
		end
	end
end