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
		action._when = 580
	end
	if distance >= 15 then
		action._when = 600
	end
	if distance >= 24 then
		action._when = 620
	end
	if distance >= 30 then
		action._when = 610
	end
	if distance >= 45 then
		action._when = 680
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(18, 70, 50)
	action.name = string.format("(%.2f) Dynamic Rockmaller Crit Timing", distance)
	return self:action(timing, action)
end
