---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local tracks = animator:GetPlayingAnimationTracks()

	-- Soul Beam shared animation
	for _, track in next, tracks do
		if track.Animation.AnimationId == "rbxassetid://7618253833" then
			local action = Action.new()
			action._when = 0
			action._type = "Start Block"
			action.hitbox = Vector3.new(15, 15, 90)
			action.name = "Shared Soul Beam Start"
			self:action(timing, action)

			local action = Action.new()
			action._when = 5000
			action._type = "End Block"
			action.hitbox = Vector3.new(15, 15, 90)
			action.name = "Shared Soul Beam End"
			return self:action(timing, action)
		end
	end

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 90)
	action.name = "Dynamic Lightning Beam Timing"
	return self:action(timing, action)
end
