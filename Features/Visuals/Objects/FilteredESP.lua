---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class FilteredESP
---@note: This is a wrapper object.
---@field object ModelESP|PartESP
---@field identifier string
---@field delayTimestamp number?
local FilteredESP = {}
FilteredESP.__index = FilteredESP
FilteredESP.__type = "FilteredESP"

---Partial look for string in list.
local partialStringFind = LPH_NO_VIRTUALIZE(function(list, value)
	for _, str in next, list do
		if not value:lower():match(str:lower()) then
			continue
		end

		return true
	end

	return false
end)

---Set visible.
---@param visible boolean
function FilteredESP:visible(visible)
	self.object:visible(visible)
end

---Detach FilteredESP.
function FilteredESP:detach()
	self.object:detach()
end

---Update FilteredESP.
---@param self FilteredESP
FilteredESP.update = LPH_NO_VIRTUALIZE(function(self)
	local object = self.object
	local identifier = self.identifier
	local label = object.label

	if Configuration.idToggleValue(identifier, "FilterObjects") then
		local filterLabelList = Configuration.idOptionValues(identifier, "FilterLabelList")
		local filterLabelListType = Configuration.idOptionValue(identifier, "FilterLabelListType")
		local filterLabelListIndex = partialStringFind(filterLabelList, label)

		if filterLabelListType == "Hide Labels Out Of List" and not filterLabelListIndex then
			return self:visible(false)
		end

		if filterLabelListType == "Hide Labels In List" and filterLabelListIndex then
			return self:visible(false)
		end
	end

	object:update()

	self.delayTimestamp = object.delayTimestamp
end)

---Create new FilteredESP object.
---@param object ModelESP|PartESP
function FilteredESP.new(object)
	local self = setmetatable({}, FilteredESP)
	self.object = object
	self.identifier = object.identifier
	self.delayTimestamp = object.delayTimestamp
	return self
end

-- Return FilteredESP module.
return FilteredESP
