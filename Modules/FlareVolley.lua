---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(1 + distance * 8, 3000)
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 100)
	action.name = string.format("(%.2f) Dynamic Flare Volley Timing", distance)

	return self:action(timing, action)
end
