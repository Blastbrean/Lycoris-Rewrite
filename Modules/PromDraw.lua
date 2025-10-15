---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(330 + distance * 4)
	action._type = "Parry"
	action.name = string.format("(%.2f) Dynamic Prominence Draw Timing", distance)

	return self:action(timing, action)
end
