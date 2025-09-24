---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	if hrp:WaitForChild("REP_SOUND_15956338865", 0.2) then
		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.hitbox = Vector3.new(0, 0, 0)
		action.name = "Yo mama Timing"
		return self:action(timing, action)
	else
		local action = Action.new()
		action._when = 1540
		action._type = "Parry"
		action.hitbox = Vector3.new(120, 120, 120)
		action.name = "Wind Forge Timing"
		return self:action(timing, action)
	end
end
