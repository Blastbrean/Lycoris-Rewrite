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

	if self.entity.Name:match(".monkyking") and self.track.Speed >= 1.5 and self.track.Speed <= 1.7 then
		timings = {
			[1] = 600,
			[2] = 1000,
			[3] = 1400,
		}
	end

	if self.entity.Name:match(".monkyking") and self.track.Speed >= 1.7 and self.track.Speed <= 2.0 then
		timings = {
			[1] = 600,
			[2] = 900,
			[3] = 1100,
		}
	end

	for idx = 1, 3 do
		local action = Action.new()
		action._when = timings[idx] or 0
		action._type = "Parry"
		action.hitbox = Vector3.new(80, 250, 80)
		action.name = string.format("(%.2f) Dynamic Primadon Timing", self.track.Speed)

		if humanoid.Health <= (humanoid.MaxHealth / 2) then
			action._when /= 1.25
		end

		self:action(timing, action)
	end
end
