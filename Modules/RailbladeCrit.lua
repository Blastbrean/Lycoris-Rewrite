---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 370
	if distance >= 10 then
		action._when = 500
	end
	if distance >= 18 then
		action._when = 670
	end
	if distance >= 23 then
		action._when = 750
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(22, 20, 43)
	action.name = string.format("(%.2f) Dynamic Railblade Timing", distance)
	return self:action(timing, action)
end
