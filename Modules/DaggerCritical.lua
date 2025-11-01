---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = 400
	if distance >= 11 then
		action._when = 650
	end
	if distance >= 13 then
		action._when = 800
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(14, 15, 15)
	action.name = string.format("(%.2f) Dynamic Dagger Crit Timing", distance)

	return self:action(timing, action)
end
