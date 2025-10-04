---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(25, 36, 55)
	action.name = string.format("(%.2f) Heavenly Wind Timing", distance)

	if self.entity.Name:match(".evengarde") then
		action._when = 350
		action.name = string.format("(%.2f) Maestro Heavenly Wind Timing", self.track.Speed)
	end

	return self:action(timing, action)
end
