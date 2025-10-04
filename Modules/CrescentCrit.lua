---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 450
	if distance >= 7 then
		action._when = 600
	end
	if distance >= 10 then
		action._when = 650
	end
	if distance >= 15 then
		action._when = 700
	end
	if distance >= 18 then
		action._when = 750
	end
	if distance >= 20 then
		action._when = 800
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 25, 25)
	action.name = string.format("(%.2f) Dynamic Crescent Crit Timing", distance)
	return self:action(timing, action)
end
