---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 650
	if distance >= 15 then
		action._when = 700
	end
	if distance >= 25 then
		action._when = 750
	end
	if distance >= 35 then
		action._when = 800
	end
	if distance >= 45 then
		action._when = 850
	end
	if distance >= 55 then
		action._when = 850
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(100, 60, 100)
	action.name = string.format("(%.2f) Dynamic Rising Thunder Timing", distance)
	return self:action(timing, action)
end
