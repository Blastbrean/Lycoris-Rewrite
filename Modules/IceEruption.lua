---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 700
	if distance >= 13 then
		action._when = 750
	end
	if distance >= 16 then
		action._when = 820
	end
	if distance >= 20 then
		action._when = 950
	end
	action._type = "Dodge"
	action.hitbox = Vector3.new(20, 20, 25)
	action.name = string.format("(%.2f) Dynamic Ice Eruption Timing", distance)
	return self:action(timing, action)
end
