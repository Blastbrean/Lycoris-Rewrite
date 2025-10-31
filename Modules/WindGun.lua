---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.1 - self.rtt())

	local action = Action.new()
	action._when = self.track.Speed > 1.00 and 0 or 400
	action._type = "Parry"
	action.name = string.format("(%.2f) Dynamic Wind Gun Timing", self.track.Speed)
	action.hitbox = Vector3.new(25, 20, 30)

	return self:action(timing, action)
end
