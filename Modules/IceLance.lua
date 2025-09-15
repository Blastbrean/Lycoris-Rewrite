---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(330 + (distance * 13), 620)
	action._type = "Parry"
	action.hitbox = Vector3.new(16, 15, 15)
	action.name = string.format("(%.2f) Dynamic Ice Lance Timing", distance)
	return self:action(timing, action)
end
