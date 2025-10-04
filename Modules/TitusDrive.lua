---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(400 + distance * 5, 800)
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 50)
	action.name = "Dynamic Titus Drive Timing"

	if self.entity.Name:match(".titus") then
		action.hitbox *= 2.0
		action._when = 740
		action._type = "Dodge"
	end

	return self:action(timing, action)
end
