---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 150
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 30, 30)
	action.name = "Dynamic Warp Kick Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox *= 2.0
		action._type = "Dodge"
		action.name = "Dynamic Titus Kick Timing"
	end

	return self:action(timing, action)
end
