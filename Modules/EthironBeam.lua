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

	if hrp:WaitForChild("REP_SOUND_2019633907", 0.1) then
		local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
		info.track = self.track

		timing.fhb = false
		timing.ieae = true
		timing.iae = true
		timing.rpue = true
		timing.imxd = 600
		timing._rsd = 1200
		timing._rpd = 250
		timing.hitbox = Vector3.new(800, 800, 800)
		return self:rpue(self.entity, timing, info)
	end
end
