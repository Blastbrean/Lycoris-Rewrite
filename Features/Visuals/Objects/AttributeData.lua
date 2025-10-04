---@class AttributeData
---@field weapon table<string, number>
---@field attunement table<string, number>
---@field base table<string, number>
local AttributeData = {}
AttributeData.__index = AttributeData

---Is it possible to meet the requirements for a specific talent or mantra?
---@note: Expects the data to be formatted correctly from DeepwokenData
---@param reqs table
---@return boolean
function AttributeData:possible(reqs)
	local mind = math.max(self.base["Intelligence"], self.base["Willpower"], self.base["Charisma"])
	local body = math.max(self.base["Strength"], self.base["Fortitude"], self.base["Agility"])

	for idx, value in pairs(reqs) do
		if self.weapon[idx] and self.weapon[idx] < value then
			return false
		end

		if self.attunement[idx] and self.attunement[idx] < value then
			return false
		end

		if self.base[idx] and self.base[idx] < value then
			return false
		end

		if idx == "Mind" and mind < value then
			return false
		end

		if idx == "Body" and body < value then
			return false
		end
	end

	return true
end

---Tally up attribute points.
---@return number
function AttributeData:points()
	local points = 0

	for _, value in pairs(self.weapon) do
		points = points + value
	end

	for _, value in pairs(self.attunement) do
		points = points + value
	end

	for _, value in pairs(self.base) do
		points = points + value
	end

	return points
end

---Compare to another AttributeData object.
---@param other AttributeData
function AttributeData:compare(other)
	for idx, value in pairs(self.weapon) do
		if other.weapon[idx] == value then
			continue
		end

		return false
	end

	for idx, value in pairs(self.attunement) do
		if other.attunement[idx] == value then
			continue
		end

		return false
	end

	for idx, value in pairs(self.base) do
		if other.base[idx] == value then
			continue
		end

		return false
	end

	return true
end

---Load from partial values.
---@param values table
function AttributeData:load(values)
	if typeof(values.weapon) == "table" then
		self.weapon = values.weapon
	end

	if typeof(values.attunement) == "table" then
		self.attunement = values.attunement
	end

	if typeof(values.base) == "table" then
		self.base = values.base
	end
end

---Create new AttributeData object.
---@param values table?
---@return AttributeData
function AttributeData.new(values)
	local self = setmetatable({}, AttributeData)

	self.weapon = {}
	self.attunement = {}
	self.base = {}

	if values then
		self:load(values)
	end

	return self
end

--- Return AttributeData module.
return AttributeData
