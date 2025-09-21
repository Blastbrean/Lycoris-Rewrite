---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 0.3

	local action = Action.new()
	action._when = 0
	action._type = "Dodge"
	action.hitbox = Vector3.new(35, 35, 35)
	action.name = string.format("(%.2f) Dynamic Golem Hammer Timing", self.track.Speed)
	self:action(timing, action)
end
