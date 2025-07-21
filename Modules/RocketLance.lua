---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 500
	if distance >= 12 then
		action._when = 550
	end
	if distance >= 15 then
		action._when = 660
	end
	if distance >= 20 then
		action._when = 680
	end
	if distance >= 22 then
		action._when = 700
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(26, 15, 32)
	action.name = string.format("(%.2f) Dynamic Rising Thunder Timing", distance)
	return self:action(timing, action)
end
