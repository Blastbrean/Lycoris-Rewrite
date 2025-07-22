---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local timings = {
		[1] = 800,
		[2] = 1400,
		[3] = 2050,
	}

	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	for idx = 1, 3 do
		local action = Action.new()
		action._when = timings[idx] or 0
		action._type = "Parry"
		action.hitbox = Vector3.new(50, 150, 50)
		action.name = "Dynamic Primadon Timing"

		if humanoid.Health <= (humanoid.MaxHealth / 2) then
			action._when /= 1.25
		end

		self:action(timing, action)
	end
end
