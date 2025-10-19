---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 15)
	action.name = "Static Spear Critical"
	return self:action(timing, action)
end
