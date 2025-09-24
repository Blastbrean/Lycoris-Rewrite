---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(550 + distance * 3, 800)
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 25, 85)
	action.name = string.format("(%.2f) Dynamic Dread Breath Timing", distance)

	return self:action(timing, action)
end
