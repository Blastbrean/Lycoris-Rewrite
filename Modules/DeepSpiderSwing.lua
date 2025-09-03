---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local speed = self.track.Speed
	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(40, 40, 40)
	action.name = string.format("(%.2f) Dynamic Spider Timing", speed)

	if speed >= 0.45 and speed <= 0.55 then
		action._when = 1050
	end

	if speed >= 0.75 and speed <= 0.85 then
		action._when = 750
	end

	if speed >= 0.9 and speed <= 1.0 then
		action._when = 540
	end

	return self:action(timing, action)
end
