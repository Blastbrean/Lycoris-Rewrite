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

	if hrp:WaitForChild("REP_SOUND_15776883341", 0.1) then
		local action = Action.new()
		action._when = 400
		action._type = "Parry"
		action.hitbox = Vector3.new(15, 15, 20)
		action.name = "Blood Scythe Timing"
		return self:action(timing, action)
	else
		local action = Action.new()
		action._when = 300
		action._type = "Parry"
		action.hitbox = Vector3.new(16, 12, 16)
		action.name = "Scythe Timing"
		return self:action(timing, action)
	end
end
