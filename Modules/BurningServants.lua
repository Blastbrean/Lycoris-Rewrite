---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local data = Mantra.data(self.entity, "Mantra:SquadFire{{Burning Servants}}")
	local data2 = Mantra.data(self.entity, "Mantra:SquadIce{{Frozen Servants}}")
	local range = data.stratus * 2 + data.cloud * 1
	local range2 = data.stratus * 2 + data.cloud * 1

	if hrp:WaitForChild("REP_SOUND_4537562107", 0.1) then
		local action = Action.new()
		action._when = 325
		action._type = "Parry"
		action.hitbox = Vector3.new(20 + range, 25, 20 + range)
		action.name = "(1) Burning Servants Timing"
		self:action(timing, action)

		local secondAction = Action.new()
		secondAction._when = math.min(2000 + range * 20, 2300)
		secondAction._type = "Parry"
		secondAction.hitbox = Vector3.new(20 + range, 25, 20 + range)
		secondAction.name = "(2) Burning Servants Timing 2"
		return self:action(timing, secondAction)
	else
		local action3 = Action.new()
		action3._when = 150
		action3._type = "Parry"
		action3.hitbox = Vector3.new(20 + range2, 25, 20 + range2)
		action3.name = "(1) Frozen Servants Timing"
		self:action(timing, action3)
	end
end
