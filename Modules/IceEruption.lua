---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local data = Mantra.data(self.entity, "Mantra:EruptionMetal{{Metal Eruption}}")
	local range = data.stratus * 2.5 + data.cloud * 1.5
	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	if hrp:WaitForChild("REP_SOUND_13263429067", 0.1) then
		local action = Action.new()
		action._when = math.min(200 + distance * 15)
		action._type = "Parry"
		action.hitbox = Vector3.new(23 + range, 20, 30 + range)
		action.name = string.format("(%.2f) Dynamic Metal Eruption Timing", distance)
		return self:action(timing, action)
	else
		local action = Action.new()
		action._when = math.min(525 + distance * 13.5)
		action._type = "Dodge"
		action.hitbox = Vector3.new(22, 20, 30)
		action.name = string.format("(%.2f) Dynamic Ice Eruption Timing", distance)
		return self:action(timing, action)
	end
end
