---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 500
	if distance >= 20 then
		action._when = 570
	end
	if distance >= 30 then
		action._when = 670
	end
	if distance >= 40 then
		action._when = 770
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(35, 20, 50)
	action.name = string.format("(%.2f) Dynamic Crimson Rain Timing", distance)
	return self:action(timing, action)
end
