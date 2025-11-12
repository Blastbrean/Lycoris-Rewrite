---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	timing.duih = true
	action._when = 0
	action._type = "Parry"
	timing.hitbox = Vector3.new(50, 58, 50)
	action.name = "Dynamic Skycrash Loop Timing"

	if self.entity.Name:match(".titus") then
		timing.hitbox = Vector3.new(100, 100, 100)
		action._type = "Dodge"
		action.name = "Dynamic Titus Skycrash Loop Timing"
	end

	return self:action(timing, action)
end
