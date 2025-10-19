---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	timing.ffh = true

	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 700
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 16, 16)
	action.name = "Boltcrusher Running Timing"
	return self:action(timing, action)
end
