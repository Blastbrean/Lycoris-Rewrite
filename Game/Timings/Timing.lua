---@module Game.Timings.ActionContainer
local ActionContainer = require("Game/Timings/ActionContainer")

---@class Timing
---@field name string
---@field tag string
---@field imdd number Initial minimum distance from position.
---@field imxd number Initial maximum distance from position.
---@field punishable number Punishable window in seconds.
---@field after number After window in seconds.
---@field duih boolean Delay until in hitbox.
---@field actions ActionContainer
---@field hitbox Vector3
---@field umoa boolean Use module over actions.
---@field smn boolean Skip module notification.
---@field srpn boolean Skip repeat notification.
---@field smod string Selected module string.
---@field aatk boolean Allow attacking.
---@field fhb boolean Hitbox facing offset.
---@field ndfb boolean No dash fallback.
---@field scrambled boolean Scrambled?
local Timing = {}
Timing.__index = Timing

---Timing ID. Override me.
---@return string
function Timing:id()
	return self.name
end

---Set timing ID. Override me.
---@param id string
function Timing:set(id)
	self.name = id
end

---Load from partial values.
---@param values table
function Timing:load(values)
	if typeof(values.name) == "string" then
		self.name = values.name
	end

	if typeof(values.tag) == "string" then
		self.tag = values.tag
	end

	if typeof(values.imdd) == "number" then
		self.imdd = values.imdd
	end

	if typeof(values.imxd) == "number" then
		self.imxd = values.imxd
	end

	if typeof(values.duih) == "boolean" then
		self.duih = values.duih
	end

	if typeof(values.punishable) == "number" then
		self.punishable = values.punishable
	end

	if typeof(values.after) == "number" then
		self.after = values.after
	end

	if typeof(values.actions) == "table" then
		self.actions:load(values.actions)
	end

	if typeof(values.smn) == "boolean" then
		self.smn = values.smn
	end

	if typeof(values.hitbox) == "table" then
		self.hitbox = Vector3.new(values.hitbox.X or 0, values.hitbox.Y or 0, values.hitbox.Z or 0)
	end

	if typeof(values.umoa) == "boolean" then
		self.umoa = values.umoa
	end

	if typeof(values.srpn) == "boolean" then
		self.srpn = values.srpn
	end

	if typeof(values.smod) == "string" then
		self.smod = values.smod
	end

	if typeof(values.aatk) == "boolean" then
		self.aatk = values.aatk
	end

	if typeof(values.fhb) == "boolean" then
		self.fhb = values.fhb
	end

	if typeof(values.ndfb) == "boolean" then
		self.ndfb = values.ndfb
	end

	if typeof(values.scrambled) == "boolean" then
		self.scrambled = values.scrambled
	end
end

---Equals check.
---@param other Timing
---@return boolean
function Timing:equals(other)
	if self.name ~= other.name then
		return false
	end

	if self.tag ~= other.tag then
		return false
	end

	if self.imdd ~= other.imdd then
		return false
	end

	if self.imxd ~= other.imxd then
		return false
	end

	if self.duih ~= other.duih then
		return false
	end

	if self.punishable ~= other.punishable then
		return false
	end

	if self.after ~= other.after then
		return false
	end

	if not self.actions:equals(other.actions) then
		return false
	end

	if self.smn ~= other.smn then
		return false
	end

	if self.hitbox ~= other.hitbox then
		return false
	end

	if self.umoa ~= other.umoa then
		return false
	end

	if self.srpn ~= other.srpn then
		return false
	end

	if self.smod ~= other.smod then
		return false
	end

	if self.aatk ~= other.aatk then
		return false
	end

	if self.fhb ~= other.fhb then
		return false
	end

	if self.ndfb ~= other.ndfb then
		return false
	end

	if self.scrambled ~= other.scrambled then
		return false
	end

	return true
end

---Clone timing.
---@return Timing
function Timing:clone()
	local clone = Timing.new()

	clone.name = self.name
	clone.tag = self.tag
	clone.duih = self.duih
	clone.imdd = self.imdd
	clone.imxd = self.imxd
	clone.smn = self.smn
	clone.punishable = self.punishable
	clone.after = self.after
	clone.actions = self.actions:clone()
	clone.hitbox = self.hitbox
	clone.umoa = self.umoa
	clone.srpn = self.srpn
	clone.smod = self.smod
	clone.aatk = self.aatk
	clone.fhb = self.fhb
	clone.ndfb = self.ndfb
	clone.scrambled = self.scrambled

	return clone
end

---Return a serializable table.
---@return table
function Timing:serialize()
	return {
		name = self.name,
		tag = self.tag,
		imdd = self.imdd,
		imxd = self.imxd,
		duih = self.duih,
		punishable = self.punishable,
		smn = self.smn,
		after = self.after,
		actions = self.actions:serialize(),
		hitbox = {
			X = self.hitbox.X,
			Y = self.hitbox.Y,
			Z = self.hitbox.Z,
		},
		srpn = self.srpn,
		umoa = self.umoa,
		smod = self.smod,
		aatk = self.aatk,
		fhb = self.fhb,
		ndfb = self.ndfb,
		scrambled = self.scrambled,
		phd = self.phd,
		pfh = self.pfh,
	}
end

---Create new Timing object.
---@param values table?
---@return Timing
function Timing.new(values)
	local self = setmetatable({}, Timing)

	self.tag = "Undefined"
	self.name = "N/A"
	self.imdd = 0
	self.imxd = 0
	self.smn = false
	self.punishable = 0
	self.after = 0
	self.duih = false
	self.actions = ActionContainer.new()
	self.hitbox = Vector3.zero
	self.umoa = false
	self.srpn = false
	self.smod = "N/A"
	self.aatk = false
	self.fhb = true
	self.ndfb = false
	self.scrambled = false

	if values then
		self:load(values)
	end

	return self
end

-- Return Timing module.
return Timing
