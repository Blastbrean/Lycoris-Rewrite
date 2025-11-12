---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	repeat
		task.wait()
	until self.track.TimePosition >= 1.18

	local action = Action.new()
	action._when = math.min(0 + distance * 8)
	action._type = "Parry"
	action.hitbox = Vector3.new(50, 50, 50)
	action.name = string.format("(%.2f) Dynamic Flame Ballista Timing", self.track.Speed)
	self:action(timing, action)
end
