---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 0.94

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(65, 65, 65)
	action.name = string.format("(%.2f) Dynamic Chaser Slam Timing", self.track.Speed)
	self:action(timing, action)
end
