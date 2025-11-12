---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(200 + distance * 15)
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 25, 34)
	action.name = string.format("(%.2f) Dynamic Twister Kicks Timing", distance)

	return self:action(timing, action)
end
