---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 740
	action._type = "Parry"
	action.hitbox = Vector3.new(18, 18, 30)
	action.name = "Dynamic Titus Drive Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox *= 2.0
		action._type = "Dodge"
	end

	return self:action(timing, action)
end
