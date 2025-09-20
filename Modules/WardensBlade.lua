---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	self:hook("rc", function(_)
		local center = self.entity:FindFirstChild("IceBladeCenter")
		if not center then
			return
		end

		if not center:FindFirstChild("IceSword") then
			return
		end

		return true
	end)

	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = self.track

	---@todo: Mantra modifiers.
	timing.fhb = false
	timing.ieae = true
	timing.iae = true
	timing.rpue = true
	timing.imxd = 100
	timing._rsd = 750
	timing._rpd = 150
	timing.hitbox = Vector3.new(20, 20, 20)
	self:rpue(self.entity, timing, info)
end
