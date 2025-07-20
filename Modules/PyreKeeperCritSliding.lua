---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 330
	if distance >= 24 then
		action._when = 550
	end
	if distance >= 28 then
		action._when = 700
	end
	if distance >= 32 then
		action._when = 720
	end
	if distance >= 36 then
		action._when = 770
	end
	if distance >= 38 then
		action._when = 780
	end
	if distance >= 40 then
		action._when = 810
	end
	if distance >= 42 then
		action._when = 840
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 20, 50)
	action.name = string.format("(%.2f) Dynamic Pyre Keeper Sliding Crit Timing", distance)
	return self:action(timing, action)
end
