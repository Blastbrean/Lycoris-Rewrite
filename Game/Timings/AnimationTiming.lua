---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class AnimationTiming: Timing
---@field id string Animation ID.
---@field rpue boolean Repeat parry until end.
---@field _rsd number Repeat start delay in miliseconds. Never access directly.
---@field _rpd number Delay between each repeat parry in miliseconds. Never access directly.
---@field ha boolean Flag to see whether or not this timing can be cancelled by a hit.
---@field iae boolean Flag to see whether or not this timing should ignore animation end.
---@field phd boolean Past hitbox detection.
---@field pfh boolean Predict hitboxes facing.
---@field phds number History seconds for past hitbox detection.
---@field pfht number Extrapolation time for hitbox prediction.
---@field ieae boolean Flag to see whether or not this timing should ignore early animation end.
---@field mat number Max animation timeout in milliseconds.
---@field dp boolean Disable prediction.
local AnimationTiming = setmetatable({}, { __index = Timing })
AnimationTiming.__index = AnimationTiming

---Timing ID.
---@return string
function AnimationTiming:id()
	return self._id
end

---Getter for repeat start delay in seconds
---@return number
function AnimationTiming:rsd()
	return PP_SCRAMBLE_NUM(self._rsd) / 1000
end

---Getter for repeat parry delay in seconds.
---@return number
function AnimationTiming:rpd()
	return PP_SCRAMBLE_NUM(self._rpd) / 1000
end

---Equals check.
---@param other AnimationTiming
function AnimationTiming:equals(other)
	if not Timing.equals(self, other) then
		return false
	end

	if self._rsd ~= other._rsd then
		return false
	end

	if self._rpd ~= other._rpd then
		return false
	end

	if self.rpue ~= other.rpue then
		return false
	end

	if self.ha ~= other.ha then
		return false
	end

	if self.iae ~= other.iae then
		return false
	end

	if self.ieae ~= other.ieae then
		return false
	end

	if self.mat ~= other.mat then
		return false
	end

	if self.phd ~= other.phd then
		return false
	end

	if self.pfh ~= other.pfh then
		return false
	end

	if self.phds ~= other.phds then
		return false
	end

	if self.pfht ~= other.pfht then
		return false
	end

	if self.dp ~= other.dp then
		return false
	end

	return true
end

---Load from partial values.
---@param values table
function AnimationTiming:load(values)
	Timing.load(self, values)

	if typeof(values._id) == "string" then
		self._id = values._id
	end

	if typeof(values.rsd) == "string" then
		self._rsd = tonumber(values.rsd) or 0.0
	end

	if typeof(values.rpd) == "string" then
		self._rpd = tonumber(values.rpd) or 0.0
	end

	if typeof(values.rsd) == "number" then
		self._rsd = values.rsd
	end

	if typeof(values.rpd) == "number" then
		self._rpd = values.rpd
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.ha) == "boolean" then
		self.ha = values.ha
	end

	if typeof(values.iae) == "boolean" then
		self.iae = values.iae
	end

	if typeof(values.ieae) == "boolean" then
		self.ieae = values.ieae
	end

	if typeof(values.mat) == "number" then
		self.mat = values.mat
	end

	if typeof(values.phd) == "boolean" then
		self.phd = values.phd
	end

	if typeof(values.pfh) == "boolean" then
		self.pfh = values.pfh
	end

	if typeof(values.phds) == "number" then
		self.phds = values.phds
	end

	if typeof(values.pfht) == "number" then
		self.pfht = values.pfht
	end

	if typeof(values.dp) == "boolean" then
		self.dp = values.dp
	end
end

---Clone timing.
---@return AnimationTiming
function AnimationTiming:clone()
	local clone = setmetatable(Timing.clone(self), AnimationTiming)

	clone._rsd = self._rsd
	clone._rpd = self._rpd
	clone._id = self._id
	clone.rpue = self.rpue
	clone.ha = self.ha
	clone.iae = self.iae
	clone.ieae = self.ieae
	clone.mat = self.mat
	clone.phd = self.phd
	clone.pfh = self.pfh
	clone.phds = self.phds
	clone.pfht = self.pfht
	clone.dp = self.dp

	return clone
end

---Return a serializable table.
---@return AnimationTiming
function AnimationTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable._id = self._id
	serializable.rsd = self._rsd
	serializable.rpd = self._rpd
	serializable.rpue = self.rpue
	serializable.ha = self.ha
	serializable.iae = self.iae
	serializable.ieae = self.ieae
	serializable.mat = self.mat
	serializable.phd = self.phd
	serializable.pfh = self.pfh
	serializable.phds = self.phds
	serializable.pfht = self.pfht
	serializable.dp = self.dp

	return serializable
end

---Create a new animation timing.
---@param values table?
---@return AnimationTiming
function AnimationTiming.new(values)
	local self = setmetatable(Timing.new(), AnimationTiming)

	self.dp = false
	self._id = ""
	self._rsd = 0
	self._rpd = 0
	self.rpue = false
	self.ha = false
	self.iae = false
	self.ieae = false
	self.mat = 2000
	self.phd = false
	self.pfh = false
	self.phds = 0
	self.pfht = 0.15

	if values then
		self:load(values)
	end

	return self
end

-- Return AnimationTiming module.
return AnimationTiming
