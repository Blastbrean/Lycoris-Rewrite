---@module Game.Timings.ActionContainer
local ActionContainer = require("Game/Timings/ActionContainer")

---@module Game.Timings.Action
local Action = require("Game/Timings/Action")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@note: We assume that all elements will exist in callbacks. This is why they are not explicitly set in the constructor.

---@class BuilderSection
---@field tabbox table
---@field pair TimingContainerPair
---@field timing Timing Dummy timing object of the correct type. Cloned to create new timings.
---@field container ActionContainer
---@field name string
---@field timingList table
---@field timingName table
---@field timingTag table
---@field hitboxLength table
---@field hitboxWidth table
---@field hitboxHeight table
---@field delayUntilInHitbox table
---@field actionList table
---@field actionName table
---@field actionDelay table
---@field actionType table
local BuilderSection = {}
BuilderSection.__index = BuilderSection

---Add extra elements to the builder tab. Override me.
---@param tab table
function BuilderSection:extra(tab) end

---Initialize action tab. Override me.
function BuilderSection:action()
	self:baction(self.tabbox:AddTab("Action"))
end

---Load the timing. Extend me.
---@param timing Timing
function BuilderSection:load(timing)
	-- Clone correct action container data.
	self.container = timing.actions:clone()

	-- Then, set the elements correctly.
	self.timingName:SetValue(timing.name)
	self.timingTag:SetValue(timing.tag)
	self.hitboxLength:SetValue(timing.hitbox.X)
	self.hitboxHeight:SetValue(timing.hitbox.Y)
	self.hitboxWidth:SetValue(timing.hitbox.Z)
	self.delayUntilInHitbox:SetValue(timing.duih)
	self.actionName:SetValue("")
	self.actionDelay:SetValue(0)
	self.actionType:SetValue("Parry")

	-- Refresh the action list.
	self:crefresh()
end

---Write to the current timing. Extend me.
function BuilderSection:write()
	self.timing.name = self.timingName.Value
	self.timing.tag = self.timingTag.Value
	self.timing.hitbox = Vector3.new(self.hitboxLength.Value, self.hitboxHeight.Value, self.hitboxWidth.Value)
	self.timing.duih = self.delayUntilInHitbox.Value
	self.timing.actions = self.container:clone()
end

---Overwrite the timing. Add or update the timing.
---@param timing Timing
function BuilderSection:overwrite(timing)
	local config = self.pair:config()

	config:overwrite(timing:clone())

	self:refresh()
end

---Remove the timing.
function BuilderSection:remove()
	local name = self.timingList.Value
	if not name then
		return Logger.longNotify("Please select a timing to remove.")
	end

	local default = self.pair:default()
	local config = self.pair:config()

	if default:find(name) then
		return Logger.longNotify("You cannot remove default timings.")
	end

	local found = config:find(name)
	if not found then
		return Logger.longNotify("The selected timing '%s' does not exist in the list.", name)
	end

	config:remove(found)

	self:refresh()
end

---Refresh timing list.
function BuilderSection:refresh()
	self.timingList:SetValues(self.pair:names())
	self.timingList:SetValue(nil)
	self.timingList:Display()
end

---Refresh action list.
function BuilderSection:crefresh()
	self.actionList:SetValues(self.container:names())
	self.actionList:SetValue(nil)
	self.actionList:Display()
end

---Initialize action base.
---@param base table
function BuilderSection:baction(base)
	self.actionList = base:AddDropdown(nil, {
		Text = "Action List",
		Values = self.container:names(),
		AllowNull = true,
		Callback = function(value)
			if not value then
				return
			end

			local action = self.container:find(value)
			if not action then
				return Logger.longNotify("The selected action '%s' does not exist in the list.", value)
			end

			self.actionName:SetValue(action.name)
			self.actionDelay:SetValue(action.when)
			self.actionType:SetValue(action._type)
		end,
	})

	self.actionName = base:AddInput(nil, {
		Text = "Action Name",
	})

	self.actionDelay = base:AddInput(nil, {
		Text = "Action Delay",
		Numeric = true,
	})

	self.actionType = base:AddDropdown(nil, {
		Text = "Action Type",
		Values = { "Parry", "Dodge", "Start Block", "End Block" },
		Default = 1,
	})

	base:AddButton("Add Action To List", function()
		if #self.actionName.Value <= 0 then
			return Logger.longNotify("Please enter a valid action name.")
		end

		if self.container:find(self.actionName.Value) then
			return Logger.longNotify("The action '%s' already exists in the list.", self.actionName.Value)
		end

		local action = Action.new()
		action._type = self.actionType.Value
		action.name = self.actionName.Value
		action.when = self.actionDelay.Value

		self.container:push(action)
		self:crefresh()
	end)

	base:AddButton("Remove Action From List", function()
		local selectedActionName = self.actionList.Value
		if not selectedActionName then
			return Logger.longNotify("Please select an action to remove.")
		end

		local action = self.container:find(selectedActionName)
		if not action then
			return Logger.longNotify("The selected action '%s' does not exist in the list.", selectedActionName)
		end

		self.container:remove(action)
		self:crefresh()
	end)
end

---Initialize builder tab.
function BuilderSection:builder()
	local tab = self.tabbox:AddTab(string.format("%s", self.name))

	self.timingList = tab:AddDropdown(nil, {
		Text = "Timing List",
		Values = self.pair:names(),
		AllowNull = true,
		Callback = function(value)
			if not value then
				return
			end

			local found = self.pair:find(value)
			if not found then
				return Logger.longNotify("The selected timing '%s' does not exist in the list.", value)
			end

			self:load(found)
		end,
	})

	self.timingName = tab:AddInput(nil, {
		Text = "Timing Name",
	})

	self.timingTag = tab:AddDropdown(nil, {
		Text = "Timing Tag",
		Values = { "Undefined", "Critical", "Mantra", "M1" },
		Default = 1,
	})

	self.hitboxLength = tab:AddSlider(nil, {
		Text = "Hitbox Length",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
	})

	self.hitboxWidth = tab:AddSlider(nil, {
		Text = "Hitbox Width",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
	})

	self.hitboxHeight = tab:AddSlider(nil, {
		Text = "Hitbox Height",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
	})

	self.delayUntilInHitbox = tab:AddToggle(nil, {
		Text = "Delay Until In Hitbox",
		Default = false,
	})

	self:extra(tab)

	tab:AddButton("Write Timing To List", function()
		self:overwrite(self:write())
	end)

	tab:AddButton("Remove Timing From List", function()
		self:remove()
	end)
end

---Initialize BuilderSection object.
function BuilderSection:init()
	self:builder()
	self:action()
end

---Create new BuilderSection object.
---@param name string
---@param tabbox table
---@param pair TimingContainerPair
---@param timing Timing
---@return BuilderSection
function BuilderSection.new(name, tabbox, pair, timing)
	local self = setmetatable({}, BuilderSection)
	self.name = name
	self.tabbox = tabbox
	self.pair = pair
	self.timing = timing
	self.container = ActionContainer.new()
	return self
end

-- Return BuilderSection module.
return BuilderSection
