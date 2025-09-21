---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 15)
	action.name = "Dynamic Titus Drive Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox *= 1.5
		action._when = 500
		action._type = "Dodge"
	end

	return self:action(timing, action)
end
