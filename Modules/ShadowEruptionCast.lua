---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local data = Mantra.data(self.entity, "Mantra:EruptionShadow{{Shadow Eruption}}")
	local dataTwo = Mantra.data(self.entity, "Mantra:RestraintShadow{{Shadow Chains}}")
	local size = data.stratus * 5.5 + data.cloud * 4.5
	local range = dataTwo.perfect * 8 + dataTwo.crystal * 6

	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local root = self.entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local action = Action.new()
	action._type = "Parry"

	if root:FindFirstChild("REP_SOUND_5188185503") then
		action._when = 1200
		action.hitbox = Vector3.new(10, 10, 15)
		action.name = "Ice Chains Timing"
		timing.iae = true
		timing.fhb = true
	elseif thrown:FindFirstChild("ChainPortalShadow") then
		action._when = math.min(200 + distance * 6)
		action.hitbox = Vector3.new(55 + range, 55 + range, 55 + range)
		action.name = "Shadow Chains Timing"
		timing.fhb = false
	else
		action._when = 0
		action.hitbox = Vector3.new(35 + size, 35 + size, 35 + size)
		action.name = "Shadow Eruption Timing"
		timing.fhb = false
	end

	self:action(timing, action)
end
