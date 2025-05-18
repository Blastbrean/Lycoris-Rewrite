---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@class InstanceESP
---@field identifier string
---@field maid Maid
---@field label string
---@field text TextLabel
---@field billboard BillboardGui
---@field instance Instance
local InstanceESP = {}
InstanceESP.__index = InstanceESP
InstanceESP.__type = "InstanceESP"

-- Formats.
local ESP_DISTANCE_FORMAT = "%s [%i]"

---Set visibility.
---@param visible boolean
function InstanceESP:visible(visible)
	self.billboard.Enabled = visible
end

---Detach InstanceESP.
function InstanceESP:detach()
	self.maid:clean()
end

---Build text.
---@param label string
---@param tags string[]
---@return string
InstanceESP.build = LPH_NO_VIRTUALIZE(function(self, label, tags)
	if #tags <= 0 then
		return label
	end

	local lines = {}
	local start = true

	for _, tag in next, tags do
		local line = lines[#lines] or label

		if not start and #line > Configuration.expectOptionValue("ESPSplitLineLength") then
			lines[#lines + 1] = tag
			continue
		end

		line = line .. " " .. tag

		lines[start and 1 or #lines] = line

		start = false
	end

	return table.concat(lines, "\n")
end)

---Update InstanceESP.
---@param position Vector3
---@param tags string[]
InstanceESP.update = LPH_NO_VIRTUALIZE(function(self, position, tags)
	local label = self.label
	local identifier = self.identifier

	if not Configuration.idToggleValue(identifier, "Enable") then
		return self:visible(false)
	end

	local camera = workspace.CurrentCamera
	local distance = (camera.CFrame.Position - position).Magnitude

	if distance > Configuration.idOptionValue(identifier, "MaxDistance") then
		return self:visible(false)
	end

	if Configuration.idToggleValue(identifier, "ShowDistance") then
		label = ESP_DISTANCE_FORMAT:format(label, distance)
	end

	-- Set visible.
	self:visible(true)

	-- Update text.
	local text = self.text
	text.Text = self:build(label, tags)
	text.TextColor3 = Configuration.idOptionValue(identifier, "Color")
	text.TextSize = Configuration.expectOptionValue("FontSize")
	text.Font = Enum.Font[Configuration.expectOptionValue("Font")] or Enum.Font.Code
end)

---Setup InstanceESP.
function InstanceESP:setup()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.AlwaysOnTop = true
	billboardGui.Size = UDim2.new(1e5, 0, 1e5, 0)
	billboardGui.Enabled = false
	billboardGui.Adornee = self.instance
	billboardGui.Parent = workspace
	billboardGui.AutoLocalize = false

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1.0
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.TextStrokeTransparency = 0.0
	textLabel.Parent = billboardGui
	textLabel.AutoLocalize = false

	self.billboard = self.maid:mark(billboardGui)
	self.text = self.maid:mark(textLabel)
end

---Create new InstanceESP object.
---@param instance Instance
---@param identifier string
---@param label string
function InstanceESP.new(instance, identifier, label)
	local self = setmetatable({}, InstanceESP)
	self.label = label
	self.instance = instance
	self.identifier = identifier
	self.maid = Maid.new()
	self:setup()
	return self
end

-- Return InstanceESP module.
return InstanceESP
