---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(200 + distance * 15)
	action._type = "Start Block"
	action.hitbox = Vector3.new(15, 15, 19)
	action.name = string.format("(1) Rising Thunder Start", distance)
	self:action(timing, action)

	local secondAction = Action.new()
	secondAction._when = math.min(500 + distance * 15)
	secondAction._type = "End Block"
	secondAction.hitbox = Vector3.new(50, 50, 50)
	secondAction.name = "(2) Rising Thunder End"
	return self:action(timing, secondAction)
end
