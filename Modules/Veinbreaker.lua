---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	timing.pfh = true

	local action = Action.new()
	action._when = math.min(100 + distance * 16, 1300)
	action._type = "Dodge"
	action.hitbox = Vector3.new(30, 20, 35)
	action.name = string.format("(%.2f) Dynamic Veinbreaker Timing", distance)

	return self:action(timing, action)
end
