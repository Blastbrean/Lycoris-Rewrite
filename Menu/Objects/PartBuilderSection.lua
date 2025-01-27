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

---Check before writing.
---@return boolean
function PartBuilderSection:check()
	if not BuilderSection.check(self) then
		return false
	end

	if not self.partName.Value or #self.partName.Value <= 0 then
		return Logger.longNotify("Please enter a valid part name.")
	end

	if self.pair:index(self.partName.Value) then
		return Logger.longNotify("The timing ID '%s' is already in the list.", self.partName.Value)
	end

	return true
end

---Load the extra elements. Override me.
---@param timing Timing
function PartBuilderSection:exload(timing)
	self.partName:SetRawValue(timing.pname)
	self.timingDelay:SetRawValue(timing._td)
	self.partContentFilter:SetRawValue({})
	self.partContentFilter:SetValues(timing.filter)
	self.partContentFilter:Display()
	self.linkedAnimationIds:SetRawValue({})
	self.linkedAnimationIds:SetValues(timing.linked)
	self.linkedAnimationIds:Display()
	self.hitboxHeight:SetRawValue(timing.hitbox.Z)
	self.hitboxWidth:SetRawValue(timing.hitbox.X)
	self.hitboxLength:SetRawValue(timing.hitbox.Y)
end

---Reset the elements. Extend me.
function PartBuilderSection:reset()
	BuilderSection.reset(self)
	self.partName:SetRawValue("")
	self.timingDelay:SetRawValue(0)
	self.partContentFilter:SetRawValue({})
	self.partContentFilter:SetValues({})
	self.partContentFilter:Display()
	self.linkedAnimationIds:SetRawValue({})
	self.linkedAnimationIds:SetValues({})
	self.linkedAnimationIds:Display()
	self.hitboxHeight:SetRawValue(0)
	self.hitboxWidth:SetRawValue(0)
	self.hitboxLength:SetRawValue(0)
end

---Create timing ID element. Override me.
---@param tab table
function PartBuilderSection:tide(tab)
	self.partName = tab:AddInput(nil, {
		Text = "Part Name",
	})
end

---Add extra elements to the builder tab.
---@param tab table
function PartBuilderSection:extra(tab)
	local delayDepBox = tab:AddDependencyBox()

	self.timingDelay = delayDepBox:AddInput(nil, {
		Text = "Timing Delay",
		Numeric = true,
		Callback = self:tnc(function(timing, value)
			timing._td = tonumber(value)
		end),
	})

	delayDepBox:SetupDependencies({
		{ self.delayUntilInHitbox, false },
	})

	self.hitboxLength = tab:AddSlider(nil, {
		Text = "Hitbox Length",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:tnc(function(timing, value)
			timing.hitbox = Vector3.new(timing.hitbox.X, timing.hitbox.Y, value)
		end),
	})

	self.hitboxWidth = tab:AddSlider(nil, {
		Text = "Hitbox Width",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:tnc(function(timing, value)
			timing.hitbox = Vector3.new(value, timing.hitbox.Y, timing.hitbox.Z)
		end),
	})

	self.hitboxHeight = tab:AddSlider(nil, {
		Text = "Hitbox Height",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:tnc(function(timing, value)
			timing.hitbox = Vector3.new(timing.hitbox.X, value, timing.hitbox.Z)
		end),
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
	---@see: VisualsTab.addFilterESP and down here...

	tab:AddButton(
		"Add Name To Filter",
		self:tnc(function(timing)
			local partContentNameValue = self.partContentName.Value

			if #partContentNameValue <= 0 then
				return Logger.longNotify("Please enter a valid filter name.")
			end

			local partContentFilterValues = timing.filter

			if not table.find(partContentFilterValues, partContentNameValue) then
				table.insert(partContentFilterValues, partContentNameValue)
			end

			self.partContentFilter:SetValues(partContentFilterValues)
			self.partContentFilter:SetValue({})
			self.partContentFilter:Display()
		end)
	)

	tab:AddButton(
		"Remove Selected From Filter",
		self:tnc(function(timing)
			local partContentFilterValues = timing.filter
			local selectedFilterNames = self.partContentFilter.Value

			for selectedFilterName, _ in next, selectedFilterNames do
				local selectedIndex = table.find(partContentFilterValues, selectedFilterName)
				if not selectedIndex then
					return Logger.longNotify(
						"The selected filter name %s does not exist in the list",
						selectedFilterName
					)
				end

				table.remove(partContentFilterValues, selectedIndex)
			end

			self.partContentFilter:SetValues(partContentFilterValues)
			self.partContentFilter:SetValue({})
			self.partContentFilter:Display()
		end)
	)

	tab:AddDivider()

	self.linkedAnimationIds = tab:AddDropdown(nil, {
		Text = "Linked Animation IDs",
		Values = {},
		Default = nil,
		AllowNull = true,
		Tooltip = "Allow target checks to happen by giving the Projectile Defender data to guess the part's owner.",
		Multi = true,
	})

	self.linkedAnimationId = tab:AddInput(nil, {
		Text = "Animation ID",
	})

	tab:AddButton(
		"Add Animation ID To Linked",
		self:tnc(function(timing)
			local linkedAnimationIdValue = self.linkedAnimationId.Value

			if #linkedAnimationIdValue <= 0 then
				return Logger.longNotify("Please enter a valid Animation ID.")
			end

			local linkedValues = timing.linked

			if not table.find(linkedValues, linkedAnimationIdValue) then
				table.insert(linkedValues, linkedAnimationIdValue)
			end

			self.linkedAnimationIds:SetValues(linkedValues)
			self.linkedAnimationIds:SetValue({})
			self.linkedAnimationIds:Display()
		end)
	)

	tab:AddButton(
		"Remove Selected From Linked",
		self:tnc(function(timing)
			local linkedValues = timing.linked
			local selectedAnimationIds = self.linkedAnimationIds.Value

			for selectedFilterName, _ in next, selectedAnimationIds do
				local selectedIndex = table.find(linkedValues, selectedFilterName)
				if not selectedIndex then
					return Logger.longNotify(
						"The selected Animation ID %s does not exist in the list",
						selectedFilterName
					)
				end

				table.remove(linkedValues, selectedIndex)
			end

			self.partContentFilter:SetValues(selectedAnimationIds)
			self.partContentFilter:SetValue({})
			self.partContentFilter:Display()
		end)
	)
end

---Initialize PartBuilderSection object.
function PartBuilderSection:init()
	self:timing()
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
