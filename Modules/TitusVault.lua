---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(50, 50, 50)
	action.name = "Dynamic Sovereign Bangle Crit Timing"

	if self.entity.Name:match(".titus") then
		action._when = 1300
		action.hitbox = Vector3.new(70, 100, 75)
		action._type = "Dodge"
		action.name = "Dynamic Titus Vault Timing"
	end

	return self:action(timing, action)
end
