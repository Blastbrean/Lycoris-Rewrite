---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local timings = {
		[1] = 550,
		[2] = 1000,
		[3] = 1500,
		[4] = 1850,
		[5] = 2300,
		[6] = 2700,
	}

	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	for idx = 1, 6 do
		local action = Action.new()
		action._when = timings[idx] or 0
		action._type = "Parry"
		action.hitbox = Vector3.new(80, 250, 140)
		action.name = string.format("(%.2f) Dynamic Primadon Timing", self.track.Speed)

		if humanoid.Health <= (humanoid.MaxHealth / 2) then
			action._when /= 1.25
		end

		self:action(timing, action)
	end
end
