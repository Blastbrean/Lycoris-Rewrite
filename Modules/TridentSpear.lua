---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(325 + distance * 17)
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 12, 15)
	action.name = string.format("(%.2f) Dynamic Trident Spear Critical", distance)

	return self:action(timing, action)
end
