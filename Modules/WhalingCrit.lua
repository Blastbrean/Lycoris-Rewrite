---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 430
	if distance >= 8 then
		action._when = 550
	end
	if distance >= 13 then
		action._when = 590
	end
	if distance >= 18 then
		action._when = 640
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(17, 10, 18)
	action.name = string.format("(%.2f) Dynamic Whaling Crit Timing", distance)
	return self:action(timing, action)
end
