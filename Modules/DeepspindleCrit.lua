---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 900
	if distance >= 15 then
		action._when = 960
	end
	if distance >= 20 then
		action._when = 1020
	end
	if distance >= 25 then
		action._when = 1080
	end
	if distance >= 33 then
		action._when = 1150
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 19, 39)
	action.name = string.format("(%.2f) Dynamic Deepspindle Running Crit Timing", distance)
	return self:action(timing, action)
end
