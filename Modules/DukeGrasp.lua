---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 1100
	if distance >= 9.5 then
		action._when = 1350
	end
	if distance >= 15 then
		action._when = 1350
	end
	if distance >= 20 then
		action._when = 1500
	end
	if distance >= 25 then
		action._when = 1700
	end
	if distance >= 30 then
		action._when = 1900
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(65, 65, 65)
	action.name = string.format("(%.2f) Dynamic Rising Thunder Timing", distance)
	return self:action(timing, action)
end
