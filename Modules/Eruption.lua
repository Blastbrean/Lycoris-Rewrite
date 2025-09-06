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

	if hrp:WaitForChild("REP_SOUND_13263429067", 0.1) then
		local distance = self:distance(self.entity)
		local action = Action.new()
		action._when = math.min(310 + distance * 13, 1000)
		action._type = "Parry"
		action.hitbox = Vector3.new(35, 20, 50)
		action.name = "Metal Eruption Timing"
		return self:action(timing, action)
	else
		local distance = self:distance(self.entity)
		local action = Action.new()
		action._when = 570
		if distance >= 13 then
			action._when = 670
		end
		if distance >= 16 then
			action._when = 690
		end
		if distance >= 20 then
			action._when = 870
		end
		action._type = "Dodge"
		action.hitbox = Vector3.new(25, 20, 30)
		action.name = "Ice Eruption Timing"
		return self:action(timing, action)
	end
end
