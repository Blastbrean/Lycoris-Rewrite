---@class Action
local Action = getfenv().Action

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local rarm3 = self.entity:FindFirstChild("RArm3")
	if not rarm3 then
		return
	end

	-- Beam.
	if rarm3:WaitForChild("Attach", 0.1) then
		local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
		info.track = self.track

		timing.mat = 3000
		timing.fhb = false
		timing.ieae = true
		timing.iae = true
		timing.rpue = true
		timing.imxd = 600
		timing._rsd = 800
		timing._rpd = 150
		timing.hitbox = Vector3.new(800, 800, 800)
		return self:srpue(self.entity, timing, info)
	-- Blinding move
	else
		local action = Action.new()
		action._when = 1400
		action._type = "Parry"
		action.hitbox = Vector3.new(800, 800, 800)
		action.name = "Ethiron Blind Timing"
		self:action(timing, action)
	end
end
