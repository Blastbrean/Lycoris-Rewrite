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

	if hrp:WaitForChild("REP_SOUND_15237686618", 0.1) then
		local distance = self:distance(self.entity)
		local action = Action.new()
		action._when = math.min(150 + distance * 11, 3000)
		action._type = "Parry"
		action.hitbox = Vector3.new(25, 25, 120)
		action.name = "Blood Scythe Timing"
		return self:action(timing, action)
	end
end
