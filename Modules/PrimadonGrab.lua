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

	local action = Action.new()
	action._when = 900
	action._type = "Forced Full Dodge"
	action.hitbox = Vector3.new(80, 250, 80)
	action.name = string.format("(%.2f) Dynamic Primadon Timing", self.track.Speed)

	if humanoid.Health <= (humanoid.MaxHealth / 2) then
		action._when /= 1.25
	end

	return self:action(timing, action)
end
