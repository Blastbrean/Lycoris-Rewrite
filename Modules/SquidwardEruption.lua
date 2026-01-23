---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local speed = self.track.Speed
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 400 + (distance * 3.8)
	action._type = "Dodge"
	action.hitbox = Vector3.new(40, 40, 50)
	action.name = string.format("(%.2f) (%.2f) Dynamic Squidward Timing", distance, self.track.Speed)

	if speed >= 0.2 and speed <= 0.3 then
		action._when = 975
		action._type = "Jump"
	end

	return self:action(timing, action)
end
