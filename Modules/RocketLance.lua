---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(300 + (distance * 18), 800)
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 20)
	action.name = string.format("(%.2f) Dynamic Rocket Lance Timing", distance)
	return self:action(timing, action)
end
