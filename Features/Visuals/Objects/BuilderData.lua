---@module Features.Visuals.Objects.DeepwokenData
local DeepwokenData = require("Features/Visuals/Objects/DeepwokenData")

---@module Features.Visuals.Objects.AttributeData
local AttributeData = require("Features/Visuals/Objects/AttributeData")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class BuilderData
---@field ddata DeepwokenData
---@field talents string[]
---@field mantras string[]
---@field pre AttributeData
---@field post AttributeData
---@field traits table<string, number>
local BuilderData = {}
BuilderData.__index = BuilderData

---Fetch attributes based on data replicated info.
---@param drinfo table
---@return AttributeData
function BuilderData:attributes(drinfo)
	return (self:ipre(drinfo) == 0) and self.pre or self.post
end

---Calculate whether or not we are in the pre-shrine state. Zero if pre-shrine, one if post-shrine. Two if we must shrine.
---@param drinfo table
---@return number
function BuilderData:ipre(drinfo)
	local currentInvestedPoints = 0

	for idx, value in next, drinfo do
		if typeof(idx) ~= "string" or not idx:match("Stat") then
			continue
		end

		if typeof(value) ~= "number" then
			continue
		end

		currentInvestedPoints = currentInvestedPoints + value
	end

	local pointsToGetToShrine = self.pre:points()
	local shrineOverrideState = Configuration.expectOptionValue("ShrineOverrideState")

	if not Configuration.expectToggleValue("ShrineDetectionOverride") then
		shrineOverrideState = nil
	end

	if shrineOverrideState == "Pre-Shrine" then
		return 0
	end

	if shrineOverrideState == "Post-Shrine" then
		return 1
	end

	if shrineOverrideState == "Must Shrine" then
		return 2
	end

	if not self:dshrine() then
		return 1
	end

	if currentInvestedPoints < pointsToGetToShrine then
		return 0
	end

	if currentInvestedPoints == pointsToGetToShrine then
		return 2
	end

	return 1
end

---Did the builder data even shrine of order at all?
---@note: No specific tag, but if they did not shrine of order, then post and pre are the same.
---@return boolean
function BuilderData:dshrine()
	return not self.pre:compare(self.post)
end

---Load from partial values.
---@param values table
function BuilderData:load(values)
	if typeof(values.talents) == "table" then
		self.talents = values.talents
	end

	if typeof(values.mantras) == "table" then
		self.mantras = values.mantras
	end

	if typeof(values.preShrine) == "table" then
		self.pre:load(values.preShrine)
	end

	if typeof(values.attributes) == "table" then
		self.post:load(values.attributes)
	end

	local stats = values.stats

	if typeof(stats) ~= "table" then
		return
	end

	local traits = stats.traits

	if typeof(traits) ~= "table" then
		return
	end

	self.traits["Vitality"] = traits["Vitality"] or 0
	self.traits["Erudition"] = traits["Erudition"] or 0
	self.traits["Proficiency"] = traits["Proficiency"] or 0
	self.traits["Songchant"] = traits["Songchant"] or 0
end

---Create new BuilderData object.
---@param bvalues table?
---@param dvalues table?
---@return BuilderData
function BuilderData.new(bvalues, dvalues)
	local self = setmetatable({}, BuilderData)

	self.ddata = DeepwokenData.new(dvalues)
	self.talents = {}
	self.mantras = {}
	self.pre = AttributeData.new()
	self.post = AttributeData.new()
	self.traits = {
		["Vitality"] = 0,
		["Erudition"] = 0,
		["Proficiency"] = 0,
		["Songchant"] = 0,
	}

	if bvalues then
		self:load(bvalues)
	end

	return self
end

-- Return BuilderData module.
return BuilderData
