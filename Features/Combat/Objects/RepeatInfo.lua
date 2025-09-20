---@note: Typed object that represents information. It's not really a true class but just needs to store the correct data.
---@class RepeatInfo
---@field track AnimationTrack?
---@field timing Timing
---@field start number
---@field index number
---@field irdelay number Initial receive delay.
---@field hmid number Hitbox visualization ID for repeat hitbox check.
local RepeatInfo = {}
RepeatInfo.__index = RepeatInfo

---Create new RepeatInfo object.
---@param timing Timing
---@param irdelay number
---@param hmid number
---@return RepeatInfo
function RepeatInfo.new(timing, irdelay, hmid)
	local self = setmetatable({}, RepeatInfo)
	self.track = nil
	self.timing = timing
	self.start = os.clock()
	self.index = 0
	self.irdelay = irdelay
	self.hmid = hmid
	return self
end

-- Return RepeatInfo module.
return RepeatInfo
