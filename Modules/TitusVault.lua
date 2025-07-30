---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local speed = self.track.Speed
	local action = Action.new()
	action._when = 1300
	action._type = "Forced Full Dodge"
	action.hitbox = Vector3.new(60, 100, 60)
	action.name = string.format("(%.2f) Dynamic Titus Vault Timing", speed)

	if speed > 0.9 and speed < 1.0 then
		action._when = 1700
	end

	return self:action(timing, action)
end
