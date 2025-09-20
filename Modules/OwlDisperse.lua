---@module Utility.Logger
local Logger = getfenv().Logger

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self EffectDefender
---@param timing EffectTiming
return function(self, timing)
	local owner = self.owner
	if not owner then
		return
	end

	local duration = self.data.Duration
	if not duration then
		return
	end

	self:hook("rc", function(info)
		if os.clock() - info.start >= (duration + 0.2) then
			return Logger.warn("(%.2f) Stopping RPUE '%s' because we've went past the duration.", duration, timing.name)
		end

		return true
	end)

	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = self.track

	timing.fhb = false
	timing.duih = true
	timing.rpue = true
	timing.imxd = 300
	timing._rsd = (duration / 2.5) * 1000
	timing._rpd = 250
	timing.hitbox = Vector3.new(100, 100, 100)
	self:rpue(self.entity, timing, info)
end
