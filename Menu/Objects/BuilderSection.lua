---@module Game.Timings.Action
local Action = require("Game/Timings/Action")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class BuilderSection
---@note: We assume that all elements will exist in callbacks. This is why they are not explicitly set in the constructor.
---@field tabbox table
---@field pair TimingContainerPair
---@field name string
---@field timingList table
---@field timingName table
---@field timingTag table
---@field hitboxLength table
---@field hitboxWidth table
---@field hitboxHeight table
---@field delayUntilInHitbox table
---@field initialMinimumDistance table
---@field initialMaximumDistance table
---@field actionList table
---@field actionName table
---@field actionDelay table
---@field actionType table
local BuilderSection = {}
BuilderSection.__index = BuilderSection

-- Services.
local stats = game:GetService("Stats")

---Create timing ID element. Override me.
---@param tab table
function BuilderSection:tide(tab) end

---Create extra elements. Override me.
---@param tab table
function BuilderSection:extra(tab) end

---Load the extra elements. Override me.
---@param timing Timing
function BuilderSection:exload(timing) end

---Reset elements. Extend me.
function BuilderSection:reset()
	-- Reset timing elements.
	self.timingName:SetRawValue("")
	self.timingTag:SetRawValue("Undefined")
	self.initialMaximumDistance:SetRawValue(0)
	self.initialMinimumDistance:SetRawValue(0)
	self.delayUntilInHitbox:SetRawValue(false)

	-- Reset action list.
	self:arefresh(nil)

	-- Reset action elements.
	self:raction()
end

---Check before creating new timing. Override me.
---@return boolean
function BuilderSection:check()
	if not self.timingName.Value or #self.timingName.Value <= 0 then
		return Logger.longNotify("Please enter a valid timing name.")
	end

	if self.pair:find(self.timingName.Value) then
		return Logger.longNotify("The timing '%s' already exists in the list.", self.timingName.Value)
	end

	return true
end

---Create new timing. Override me.
---@return Timing
function BuilderSection:create()
	local timing = Timing.new()
	timing.name = self.timingName.Value
	return timing
end

---Initialize action tab. Extend me.
function BuilderSection:action()
	self:baction(self.tabbox:AddTab("Action"))
end

---Reset action elements.
function BuilderSection:raction()
	---@bug: Action names sometimes may affect the actual action and set it's data to ""
	self.actionName:SetRawValue("")
	self.actionDelay:SetRawValue(0)
	self.actionType:SetRawValue("Parry")
	self.hitboxHeight:SetRawValue(0)
	self.hitboxLength:SetRawValue(0)
	self.hitboxWidth:SetRawValue(0)
end

---Refresh timing list.
function BuilderSection:refresh()
	local values = self.timingType.Value == "Internal" and self.pair.internal:names() or self.pair.config:names()
	self.timingList:SetValues(values)
	self.timingList:SetValue(nil)
	self.timingList:Display()
end

---Refresh action list.
---@param timing Timing?
function BuilderSection:arefresh(timing)
	self.actionList:SetValues(timing and timing.actions:names() or {})
	self.actionList:SetValue(nil)
	self.actionList:Display()
end

---Wrap a callback that needs a timing. This will check for internal timings.
---@param callback function(Timing, ...)
function BuilderSection:tnc(callback)
	return function(...)
		-- If no value, return.
		if not self.timingList.Value then
			return Logger.warn("No timing selected.")
		end

		-- Find timing.
		local timing = self.pair:find(self.timingList.Value)
		if not timing then
			return Logger.longNotify("You must select a valid timing to perform this action.")
		end

		-- Check timing type.
		if self.timingType.Value == "Internal" then
			return Logger.longNotify("Internal timing. Changes not replicated. You must clone it to the config first.")
		end

		-- Fire callback.
		callback(timing, ...)
	end
end

---Wrap a callback that needs a action. This will check for internal timings.
---@param callback function(Action, ...)
function BuilderSection:anc(callback)
	return function(...)
		-- If no value, return.
		if not self.timingList.Value then
			return Logger.warn("No timing selected.")
		end

		-- Find timing.
		local timing = self.pair:find(self.timingList.Value)
		if not timing then
			return Logger.longNotify("You must select a valid timing to perform this action.")
		end

		-- If no value, return.
		if not self.actionList.Value then
			return Logger.warn("No action selected.")
		end

		-- Find action.
		local action = timing.actions:find(self.actionList.Value)
		if not action then
			return Logger.longNotify("You must select a valid action to perform this action.")
		end

		-- Check timing type.
		if self.timingType.Value == "Internal" then
			return Logger.longNotify("Internal timing. Changes not replicated. You must clone it to the config first.")
		end

		-- Fire callback.
		callback(action, ...)
	end
end

---Initialize action base.
---@param base table
function BuilderSection:baction(base)
	self.actionList = base:AddDropdown(nil, {
		Text = "Action List",
		Values = {},
		AllowNull = true,
		Callback = self:tnc(function(timing, value)
			-- Reset action elements.
			self:raction()

			-- Check if value exists.
			if not value then
				return Logger.warn("No action value.")
			end

			-- Find action.
			local action = timing.actions:find(value)
			if not action then
				return Logger.longNotify("The selected action '%s' does not exist in the list.", value)
			end

			-- Set action elements.
			self.actionName:SetRawValue(action.name)
			self.actionDelay:SetRawValue(action._when)
			self.actionType:SetRawValue(action._type)
			self.hitboxWidth:SetRawValue(action.hitbox.X)
			self.hitboxHeight:SetRawValue(action.hitbox.Y)
			self.hitboxLength:SetRawValue(action.hitbox.Z)
		end),
	})

	self.actionName = base:AddInput(nil, {
		Text = "Action Name",
		Finished = true,
		Callback = self:anc(function(action, value)
			action.name = value
		end),
	})

	self.actionDelay = base:AddInput(nil, {
		Text = "Action Delay",
		Numeric = true,
		Callback = self:anc(function(action, value)
			action._when = tonumber(value)
		end),
	})

	self.actionType = base:AddDropdown(nil, {
		Text = "Action Type",
		Values = { "Parry", "Dodge", "Start Block", "End Block" },
		Default = 1,
		Callback = self:anc(function(action, value)
			action._type = value
		end),
	})

	self.hitboxLength = base:AddSlider(nil, {
		Text = "Hitbox Length",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:anc(function(action, value)
			action.hitbox = Vector3.new(action.hitbox.X, action.hitbox.Y, value)
		end),
	})

	self.hitboxWidth = base:AddSlider(nil, {
		Text = "Hitbox Width",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:anc(function(action, value)
			action.hitbox = Vector3.new(value, action.hitbox.Y, action.hitbox.Z)
		end),
	})

	self.hitboxHeight = base:AddSlider(nil, {
		Text = "Hitbox Height",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:anc(function(action, value)
			action.hitbox = Vector3.new(action.hitbox.X, value, action.hitbox.Z)
		end),
	})

	base:AddButton(
		"Add Action To List",
		self:tnc(function(timing)
			-- Check name.
			if not self.actionName.Value or #self.actionName.Value <= 0 then
				return Logger.longNotify("Please enter a valid action name.")
			end

			-- Check for existing action.
			if timing.actions:find(self.actionName.Value) then
				return Logger.longNotify("The action '%s' already exists in the list.", self.actionName.Value)
			end

			-- Fetch actions.
			local actions = timing.actions

			-- Create new action.
			local action = Action.new()
			action.name = self.actionName.Value
			action._when = self.actionDelay.Value
			action._type = self.actionType.Value
			action.hitbox = Vector3.new(self.hitboxWidth.Value, self.hitboxHeight.Value, self.hitboxLength.Value)

			-- Record ping for telemetry.
			local network = stats:FindFirstChild("Network")
			local serverStatsItem = network and network:FindFirstChild("ServerStatsItem")
			local dataPingItem = serverStatsItem and serverStatsItem:FindFirstChild("Data Ping")

			if dataPingItem then
				action.ping = dataPingItem:GetValue()
			end

			-- Push action.
			actions:push(action)

			-- Refresh action list.
			self:arefresh(timing)
		end)
	)

	base:AddButton(
		"Remove Selected Action",
		self:tnc(function(timing)
			-- Get selected value.
			local selected = self.actionList.Value
			if not selected then
				return Logger.longNotify("Please select an action to remove.")
			end

			-- Fetch actions.
			local actions = timing.actions

			-- Find action.
			local action = actions:find(selected)
			if not action then
				return Logger.longNotify("The selected action '%s' does not exist in the list.", selected)
			end

			-- Remove action.
			actions:remove(action)

			-- Refresh action list.
			self:arefresh(timing)
		end)
	)
end

---Initialize timing tab.
function BuilderSection:timing()
	local tab = self.tabbox:AddTab("Timings")

	self.timingType = tab:AddDropdown(nil, {
		Text = "Timing Type",
		Values = { "Config", "Internal" },
		Default = 1,
		Callback = function()
			-- Refresh timing list.
			self:refresh()

			-- Reset elements.
			self:reset()
		end,
	})

	self.timingList = tab:AddDropdown(nil, {
		Text = "Timing List",
		Values = self.timingType.Value == "Internal" and self.pair.internal:names() or self.pair.config:names(),
		AllowNull = true,
		Callback = function(value)
			-- Reset elements.
			self:reset()

			-- Check if value exists.
			if not value then
				return Logger.warn("No timing value.")
			end

			-- Fetch timing.
			local found = self.pair:find(value)
			if not found then
				return Logger.longNotify("The selected timing '%s' does not exist in the list.", value)
			end

			-- Set timing elements.
			self.timingName:SetRawValue(found.name)
			self.timingTag:SetRawValue(found.tag)
			self.initialMaximumDistance:SetRawValue(found.imxd)
			self.initialMinimumDistance:SetRawValue(found.imdd)
			self.delayUntilInHitbox:SetRawValue(found.duih)

			-- Load extra elements.
			self:exload(found)

			-- Refresh action list.
			self:arefresh(found)
		end,
	})

	self.timingName = tab:AddInput(nil, {
		Text = "Timing Name",
		Finished = true,
	})

	self:tide(tab)

	local configDepBox = tab:AddDependencyBox()

	---@note: Look into writing the current timing element data like we do for Actions (?)
	configDepBox:AddButton("Create Empty Timing", function()
		-- Fetch config.
		local config = self.pair.config

		-- Check if we can successfully create a timing from the given data.
		if not self:check() then
			return
		end

		-- Push new timing.
		config:push(self:create())

		-- Refresh timing list.
		self:refresh()
	end)

	local internalDepBox = tab:AddDependencyBox()

	internalDepBox:AddButton("Clone To Config", function()
		-- Fetch name.
		local name = self.timingList.Value
		if not name then
			return Logger.longNotify("Please select a timing to clone.")
		end

		-- Fetch data.
		local internal = self.pair.internal
		local config = self.pair.config

		-- Fetch the currently selected timing.
		local found = internal:find(name)
		if not found then
			return Logger.longNotify("The selected timing '%s' does not exist in the list.", name)
		end

		-- Check for existing ID.
		if config.timings[found:id()] then
			return Logger.longNotify("The timing ID '%s' already exists in the config.", found:id())
		end

		-- Check for existing timing.
		if config:find(found.name) then
			return Logger.longNotify("The timing name '%s' already exists in the config.", found.name)
		end

		-- Clone timing.
		---@note: No need to refresh after this. It's in the other timing list!
		config:push(internal:clone(found))
	end)

	tab:AddButton("Remove Selected Timing", function()
		-- Fetch name.
		local name = self.timingList.Value
		if not name then
			return Logger.longNotify("Please select a timing to remove.")
		end

		-- Fetch data.
		local internal = self.pair.internal
		local config = self.pair.config
		local found = config:find(name)

		-- Check if internal.
		---@todo: Implement functionality to remove internal timings.
		if internal:find(name) then
			return Logger.longNotify("You cannot remove internal timings yet.")
		end

		-- Check if found.
		if not found then
			return Logger.longNotify("The selected timing '%s' does not exist in the list.", name)
		end

		-- Remove timing.
		config:remove(found)

		-- Refresh timing list.
		self:refresh()
	end)

	configDepBox:SetupDependencies({
		{ self.timingType, "Config" },
	})

	internalDepBox:SetupDependencies({
		{ self.timingType, "Internal" },
	})
end

---Initialize builder tab.
function BuilderSection:builder()
	local tab = self.tabbox:AddTab(string.format("%s", self.name))

	self.timingTag = tab:AddDropdown(nil, {
		Text = "Timing Tag",
		Values = { "Undefined", "Critical", "Mantra", "M1" },
		Default = 1,
		Callback = self:tnc(function(timing, value)
			timing.tag = value
		end),
	})

	self.initialMinimumDistance = tab:AddSlider(nil, {
		Text = "Initial Minimum Distance",
		Min = 0,
		Max = 300,
		Suffix = "s",
		Default = 0,
		Rounding = 0,
		Callback = self:tnc(function(timing, value)
			timing.imdd = value
		end),
	})

	self.initialMaximumDistance = tab:AddSlider(nil, {
		Text = "Initial Maximum Distance",
		Min = 0,
		Max = 2500,
		Suffix = "s",
		Default = 1000,
		Rounding = 0,
		Callback = self:tnc(function(timing, value)
			timing.imxd = value
		end),
	})

	self.delayUntilInHitbox = tab:AddToggle(nil, {
		Text = "Delay Until In Hitbox",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing.duih = value
		end),
	})

	self:extra(tab)
end

---Initialize BuilderSection object.
function BuilderSection:init()
	self:timing()
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
	return self
end

-- Return BuilderSection module.
return BuilderSection
