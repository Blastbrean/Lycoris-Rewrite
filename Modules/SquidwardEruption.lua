---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 400 + (distance * 4)
	action._type = "Dodge"
	action.hitbox = Vector3.new(40, 40, 40)
	action.name = string.format("(%.2f) Dynamic Squidward Timing", distance)
	return self:action(timing, action)
end
