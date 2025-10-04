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

	if hrp:WaitForChild("REP_SOUND_3755636152", 0.1) then
		local action = Action.new()
		action._when = 450
		action._type = "Parry"
		action.hitbox = Vector3.new(20, 15, 20)
		action.name = "(1) Ignition Crit Timing"
		self:action(timing, action)

		local action2 = Action.new()
		action2._when = 900
		action2._type = "Parry"
		action2.hitbox = Vector3.new(40, 15, 40)
		action2.name = "(2) Ignition Crit Timing"
		self:action(timing, action2)
	end
	if hrp:WaitForChild("REP_SOUND_13263429067", 0.1) then
		local action = Action.new()
		action._when = 250
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 15, 35)
		action.name = "(1) Pleetsky's Inferno Crit"
		self:action(timing, action)
	else
		local action3 = Action.new()
		action3._when = 300
		action3._type = "Parry"
		action3.hitbox = Vector3.new(40, 15, 40)
		action3.name = "(1) Fire Eruption Timing"
		self:action(timing, action3)

		local action4 = Action.new()
		action4._when = 1100
		action4._type = "Parry"
		action4.hitbox = Vector3.new(40, 15, 40)
		action4.name = "(2) Fire Eruption Timing"
		self:action(timing, action4)
	end
end
