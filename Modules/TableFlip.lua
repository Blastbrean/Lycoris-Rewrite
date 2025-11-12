---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(400 + distance * 10.5)
	if self:distance(self.entity) > 51 then
		action._when = 1025
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 70)
	action.name = string.format("(%.2f) Dynamic Table Flip Timing", distance)

	return self:action(timing, action)
end
