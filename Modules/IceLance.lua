---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 440
	if distance >= 13 then
		action._when = 620
	end
	if distance >= 16 then
		action._when = 680
	end
	if distance >= 20 then
		action._when = 730
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(22, 20, 30)
	action.name = string.format("(%.2f) Dynamic Ice Lance Timing", distance)
	return self:action(timing, action)
end
