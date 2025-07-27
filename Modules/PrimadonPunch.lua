---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = (1000 * 0.67) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(80, 250, 80)
	action.name = string.format("(%.2f) Dynamic Primadon Timing", self.track.Speed)
	return self:action(timing, action)
end
