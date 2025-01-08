---@module Utility.ReferencedMap
local ReferencedMap = require("Utility/ReferencedMap")

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class Group: ReferencedMap
---@field part number
---@field updated boolean
---@field identifier string
local Group = setmetatable({}, ReferencedMap)
Group.__index = Group

---Update ESP object.
---@param object ModelESP|PartESP|FilteredESP
local function updateESPObject(object)
	local delayTimestamp = object.delayTimestamp

	if delayTimestamp and os.clock() <= delayTimestamp then
		if object.__type ~= "PlayerESP" or not Configuration.toggleValue("DelayIgnorePlayers") then
			return
		end
	end

	Profiler.run(string.format("ESP_Update_%s", object.identifier), object.update, object)
end

---Update group.
function Group:update()
	local map = self:data()

	if not Configuration.idToggleValue(self.identifier, "Enable") then
		return self:hide()
	end

	if Configuration.toggleValue("ESPSplitUpdates") then
		local totalElements = #map
		local totalFrames = Configuration.optionValue("ESPSplitFrames")

		local objectsPerPart = math.ceil(totalElements / totalFrames)
		local currentPart = self.part

		local startIdx = (currentPart - 1) * objectsPerPart + 1
		local endIdx = math.min(currentPart * objectsPerPart, totalElements)

		for i = startIdx, endIdx do
			updateESPObject(map[i])
		end

		self.part = self.part + 1

		if self.part > totalFrames then
			self.part = 1
		end
	else
		for _, object in next, map do
			updateESPObject(object)
		end

		self.part = 1
	end

	self.updated = true
end

---Hide group.
function Group:hide()
	if not self.updated then
		return
	end

	for _, object in next, self:data() do
		object:setVisible(false)
	end

	self.updated = false
end

---Detach group.
function Group:detach()
	for _, object in next, self:data() do
		object:detach()
	end
end

---Create new Group object.
---@param identifier string
---@return Group
function Group.new(identifier)
	local self = setmetatable(ReferencedMap.new(), Group)
	self.part = 1
	self.updated = true
	self.identifier = identifier
	return self
end

-- Return Group module.
return Group
