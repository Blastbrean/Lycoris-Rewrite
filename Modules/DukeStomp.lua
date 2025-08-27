---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 700
	if distance >= 30 then
		action._when = 850
	end
	if distance >= 40 then
		action._when = 950
	end
	if distance >= 50 then
		action._when = 1050
	end
	action._type = "Dodge"
	action.hitbox = Vector3.new(25, 40, 60)
	action.name = string.format("(%.2f) Dynamic Duke Stomp Timing", distance)
	return self:action(timing, action)
end
