---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 300
	if distance >= 12 then
		action._when = 350
	end
	if distance >= 15 then
		action._when = 480
	end
	if distance >= 20 then
		action._when = 500
	end
	if distance >= 22 then
		action._when = 680
	end
	if distance >= 27 then
		action._when = 710
	end
	if distance >= 30 then
		action._when = 800
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 15, 40)
	action.name = string.format("(%.2f) Dynamic Dual Curved Blade Crit Timing", distance)
	return self:action(timing, action)
end
