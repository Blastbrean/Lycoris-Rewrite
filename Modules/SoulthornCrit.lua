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

	if hrp:WaitForChild("REP_SOUND_18511675827", 0.1) then
		local action = Action.new()
		action._when = 200
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 30, 30)
		action.name = "Soulthorn 3 Stacks Timing"
		return self:action(timing, action)
	end
end
