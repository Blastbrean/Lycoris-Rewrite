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

	if hrp:WaitForChild("REP_SOUND_4377231054", 0.1) then
		local action = Action.new()
		action._when = 450
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 20, 30)
		action.name = "Gale Punch Timing"
		return self:action(timing, action)
	else
		local action = Action.new()
		action._when = 500
		action._type = "Parry"
		action.hitbox = Vector3.new(28, 20, 43)
		action.name = "Fire Palm Timing"
		return self:action(timing, action)
	end
end
