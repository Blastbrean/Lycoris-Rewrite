---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 550
	if distance >= 13 then
		action._when = 750
	end
	if distance >= 18 then
		action._when = 800
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(12, 12, 21)
	action.name = string.format("(%.2f) Dynamic Tanto Crit Timing", distance)
	return self:action(timing, action)
end
