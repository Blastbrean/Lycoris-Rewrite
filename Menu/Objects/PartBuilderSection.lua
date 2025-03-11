---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Timings.PartTiming
local PartTiming = require("Game/Timings/PartTiming")

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
	self.linkedAnimationIds:SetRawValue({})
	self.linkedAnimationIds:SetValues(timing.linked)
	self.linkedAnimationIds:Display()
end

---Reset the elements. Extend me.
function PartBuilderSection:reset()
	BuilderSection.reset(self)
	self.partName:SetRawValue("")
	self.linkedAnimationIds:SetRawValue({})
	self.linkedAnimationIds:SetValues({})
	self.linkedAnimationIds:Display()
end

---Set creation timing properties. Override me.
---@param timing PartTiming
function PartBuilderSection:cset(timing)
	timing.name = self.timingName.Value
	timing.pname = self.partName.Value
end

---Create new timing. Override me.
---@return PartTiming
function PartBuilderSection:create()
	local timing = PartTiming.new()
	self:cset(timing)
	return timing
end

---Create timing ID element. Override me.
---@param tab table
function PartBuilderSection:tide(tab)
	self.partName = tab:AddInput(nil, {
		Text = "Part Name",
	})
end

---Initialize filter tab.
function PartBuilderSection:filter()
	local tab = self.tabbox:AddTab("Filter")

	---@note: De-duplicate me?
	---@see: VisualsTab.addFilterESP and down here...

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
