---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 400
	if distance >= 30 then
		action._when = 500
	end
	if distance >= 40 then
		action._when = 600
	end
	if distance >= 50 then
		action._when = 700
	end
	if distance >= 60 then
		action._when = 800
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 80)
	action.name = string.format("(%.2f) Dynamic Electro Carve Magnet Timing", distance)
	return self:action(timing, action)
end
