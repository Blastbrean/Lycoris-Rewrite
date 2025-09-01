---@class DeepwokenData
---@field talents table
---@field mantras table
local DeepwokenData = {}
DeepwokenData.__index = DeepwokenData

---Get data for a specific talent or mantra.
---@param name string
function DeepwokenData:get(name)
	return self.talents[string.lower(name)] or self.mantras[string.lower(name)]
end

---Are we able to get a specified talent or mantra with the passed in attribute data?
---@param name string
---@param adata AttributeData
---@return boolean
function DeepwokenData:possible(name, adata)
	local data = self:get(name)
	if not data then
		return false
	end

	local reqs = data.reqs
	if not reqs then
		return false
	end

	---@note: Format this table for clean requirement parsing
	local formatted = {}

	for idx, value in pairs(reqs.base) do
		formatted[idx] = value
	end

	for idx, value in pairs(reqs.weapon) do
		formatted[idx] = value
	end

	for idx, value in pairs(reqs.attunement) do
		formatted[idx] = value
	end

	return adata:possible(formatted)
end

---Load from partial values.
---@param values table
function DeepwokenData:load(values)
	if typeof(values.talents) == "table" then
		self.talents = values.talents
	end

	if typeof(values.mantras) == "table" then
		self.mantras = values.mantras
	end
end

---Create new DeepwokenData object.
---@param values table?
---@return DeepwokenData
function DeepwokenData.new(values)
	local self = setmetatable({}, DeepwokenData)

	self.talents = {}
	self.mantras = {}

	if values then
		self:load(values)
	end

	return self
end

-- Return DeepwokenData module.
return DeepwokenData
