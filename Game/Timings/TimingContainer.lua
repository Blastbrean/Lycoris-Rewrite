---@module Utility.Logger
local Logger = require("Utility/Logger")

---@class TimingContainer
---@field timings table<string, Timing>
---@field module Timing
local TimingContainer = {}
TimingContainer.__index = TimingContainer

---Merge timing container.
---@param other TimingContainer
---@param type MergeType
function TimingContainer:merge(other, type)
	assert(type ~= 1 and type ~= 2, "Invalid timing table merge type")

	for idx, timing in next, other.timings do
		if type == 1 and timing[idx] then
			continue
		end

		self.timings[idx] = timing
	end
end

---Find a timing from name.
---@param name string
---@return Timing?
function TimingContainer:find(name)
	for _, timing in next, self.timings do
		if timing.name ~= name then
			continue
		end

		return timing
	end
end

---List all timings.
---@return Timing[]
function TimingContainer:list()
	local timings = {}

	for _, timing in next, self.timings do
		timings[#timings + 1] = timing
	end

	return timings
end

---Get names of all timings.
---@return string[]
function TimingContainer:names()
	local names = {}

	for _, timing in next, self.timings do
		names[#names + 1] = timing.name
	end

	table.sort(names)

	return names
end

---Remove a timing from the list.
---@param timing Timing
function TimingContainer:remove(timing)
	local id = timing:id()
	if not id then
		return
	end

	self.timings[id] = nil
end

---Push a timing to the list.
---@param timing Timing
function TimingContainer:push(timing)
	local id = timing:id()
	if not id then
		return
	end

	---@note: Timing array keys must all be unique.
	if self.timings[id] then
		return error(string.format("Timing identifier '%s' already exists in container.", id))
	end

	---@note: Every timing must have unique names.
	if self:find(timing.name) then
		return error(string.format("Timing name '%s' already exists in container.", timing.name))
	end

	self.timings[id] = timing
end

---Clear all timings.
function TimingContainer:clear()
	self.timings = {}
end

---Get timing count.
---@return number
function TimingContainer:count()
	local count = 0

	for _ in next, self.timings do
		count = count + 1
	end

	return count
end

---Load from partial values.
---@param values table
function TimingContainer:load(values)
	for _, value in next, values do
		local timing = self.module.new(value)
		if not timing then
			continue
		end

		local id = timing:id()
		if not id then
			continue
		end

		---@note: Timing array keys must all be unique.
		if self.timings[id] then
			return error(string.format("Timing identifier '%s' already exists in container.", id))
		end

		---@note: Every timing must have unique names.
		if self:find(timing.name) then
			return error(string.format("Timing name '%s' already exists in container.", timing.name))
		end

		---@note: Why are the stored timing keys different from what's loaded?
		--- Internally, all timings are stored by their identifiers.
		--- This helps to quickly find a timing by its identifier. Example - an animation ID.
		--- Although, this does not mean each identifier must have a meaning. It can be random.

		self.timings[id] = timing
	end
end

---Return a serializable table.
---@return table
function TimingContainer:serialize()
	local out = {}

	for _, timing in next, self.timings do
		out[#out + 1] = timing:serialize()
	end

	return out
end

---Create new TimingContainer object.
---@param module Timing
---@return TimingContainer
function TimingContainer.new(module)
	local self = setmetatable({}, TimingContainer)
	self.timings = {}
	self.module = module
	return self
end

-- Return TimingContainer module.
return TimingContainer
