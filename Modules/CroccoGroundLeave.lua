---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 0
	action._type = "Dodge"
	action.hitbox = Vector3.new(30, 30, 30)
	action.name = "Dynamic Crocco Timing"

	if self.entity.Name:match("king") then
		action.hitbox *= 2.0
	end

	return self:action(timing, action)
end
