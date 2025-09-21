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
	action.name = "Dynamic Warp Kick Windup Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox = Vector3.new(20, 20, 25)
		action._type = "Dodge"
		action.name = "Dynamic Titus Kick Windup Timing"
	end

	return self:action(timing, action)
end
