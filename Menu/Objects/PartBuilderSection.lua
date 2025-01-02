---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@class PartBuilderSection: BuilderSection
---@field partName table
---@field timingDelay table
---@field partContentFilter table
---@field partContentName table
---@field initialMinimumDistance table
---@field initialMaximumDistance table
---@field timing PartTiming
local PartBuilderSection = setmetatable({}, { __index = BuilderSection })
PartBuilderSection.__index = PartBuilderSection

---Add extra elements to the builder tab.
---@param tab table
function PartBuilderSection:extra(tab)
	local delayDepBox = tab:AddDependencyBox()

	self.timingDelay = delayDepBox:AddInput(nil, {
		Text = "Timing Delay",
		Numeric = true,
	})

	delayDepBox:SetupDependencies({
		{ self.delayUntilInHitbox, false },
	})

	self.partName = tab:AddInput(nil, {
		Text = "Part Name",
	})

	self.initialMinimumDistance = tab:AddSlider(nil, {
		Text = "Initial Minimum Distance",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 10,
		Rounding = 0,
	})

	self.initialMaximumDistance = tab:AddSlider(nil, {
		Text = "Initial Maximum Distance",
		Min = 300,
		Max = 2500,
		Suffix = "s",
		Default = 1000,
		Rounding = 0,
	})
end

---Initialize filter tab.
function PartBuilderSection:filter()
	local tab = self.tabbox:AddTab("Filter")

	self.partContentFilter = tab:AddDropdown(nil, {
		Text = "Part Content Filter",
		Values = {},
		Default = nil,
		AllowNull = true,
		Multi = true,
	})

	self.partContentName = tab:AddInput(nil, {
		Text = "Part Content Name",
	})

	---@note: De-duplicate me?
	---@see: VisualsTab.addFilterESP

	tab:AddButton("Add Name To Filter", function()
		local partContentNameValue = self.partContentName.Value

		if #partContentNameValue <= 0 then
			return Logger.longNotify("Please enter a valid filter name.")
		end

		local partContentFilterValues = self.partContentFilter.Values

		if not table.find(partContentFilterValues, partContentNameValue) then
			table.insert(partContentFilterValues, partContentNameValue)
		end

		self.partContentFilter:SetValues(partContentFilterValues)
		self.partContentFilter:SetValue({})
		self.partContentFilter:Display()
	end)

	tab:AddButton("Remove Selected From Filter", function()
		local partContentFilterValues = self.partContentFilter.Values
		local selectedFilterNames = self.partContentFilter.Value

		for selectedFilterName, _ in next, selectedFilterNames do
			local selectedIndex = table.find(partContentFilterValues, selectedFilterName)
			if not selectedIndex then
				return Logger.longNotify("The selected filter name %s does not exist in the list", selectedFilterName)
			end

			table.remove(partContentFilterValues, selectedIndex)
		end

		self.partContentFilter:SetValues(partContentFilterValues)
		self.partContentFilter:SetValue({})
		self.partContentFilter:Display()
	end)
end

---Load the timing.
---@param timing PartTiming
function PartBuilderSection:load(timing)
	BuilderSection.load(self, timing)

	self.partName:SetValue(timing.pname)
	self.timingDelay:SetValue(timing.td)
	self.initialMaximumDistance:SetValue(timing.imdd)
	self.initialMinimumDistance:SetValue(timing.imxd)

	self.partContentFilter:SetValues(timing.filter)
	self.partContentFilter:SetValue({})
	self.partContentFilter:Display()
end

---Write to the current timing.
function PartBuilderSection:write()
	BuilderSection.write(self)

	self.timing.pname = self.partName.Value
	self.timing.td = self.timingDelay.Value
	self.timing.imdd = self.initialMaximumDistance.Value
	self.timing.imxd = self.initialMinimumDistance.Value
	self.timing.filter = self.partContentFilter.Values
end

---Initialize PartBuilderSection object.
function PartBuilderSection:init()
	self:builder()
	self:action()
	self:filter()
end

---Create new PartBuilderSection object.
---@param name string
---@param tabbox table
---@param pair TimingContainerPair
---@param timing PartTiming
---@return PartBuilderSection
function PartBuilderSection.new(name, tabbox, pair, timing)
	return setmetatable(BuilderSection.new(name, tabbox, pair, timing), PartBuilderSection)
end

-- Return PartBuilderSection module.
return PartBuilderSection
