---@module Utility.Logger
local Logger = getfenv().Logger

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self PartDefender
---@param timing PartTiming
return function(self, timing)
	local entity = self.part.Parent.Parent
	if not entity then
		return
	end

	self:hook("rc", function(_, info)
		if os.clock() - info.start >= 2.0 then
			return Logger.warn("(%.2f) Stopping RPUE '%s' because we've went past the duration.", 2.0, timing.name)
		end

		return true
	end)

	timing.rsd = function()
		return 0.0
	end

	timing.rpd = function()
		return 0.2
	end

	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	self:srpue(entity, timing, info)
end
