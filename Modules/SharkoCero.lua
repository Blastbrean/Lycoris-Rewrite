---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	repeat
		task.wait()
	until self.track.TimePosition >= 2.89

	local action = Action.new()
	action._when = 0
	action._type = "Forced Full Dodge"
	action.hitbox = Vector3.new(50, 65, 145)
	action.name = string.format("(%.2f) Dynamic Sharko Cero Timing", self.track.Speed)
	self:action(timing, action)
end
