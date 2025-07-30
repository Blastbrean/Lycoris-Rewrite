---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 200
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 30, 30)
	action.name = "Dynamic Titus Kick Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox *= 2.0
		action._type = "Dodge"
	end

	return self:action(timing, action)
end
