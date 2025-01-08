---@module Utility.DrawingPool
local DrawingPool = require("Utility/DrawingPool")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class PositionESP: DrawingPool
---@field identifier string
---@field delayTimestamp number?
---@field label string
local PositionESP = setmetatable({}, { __index = DrawingPool })
PositionESP.__index = PositionESP

-- Formats.
local ESP_DISTANCE_FORMAT = "%s [%i]"

---Hide PositionESP and delay the next update.
function PositionESP:hide()
	if Configuration.toggleValue("ESPCheckDelay") then
		self.delayTimestamp = os.clock() + Configuration.optionValue("ESPCheckDelayTime")
	end

	return self:setVisible(false)
end

---Build text.
---@param label string
---@param tags string[]
---@return string
function PositionESP:build(label, tags)
	if #tags <= 0 then
		return label
	end

	local lines = {}
	local start = true

	for _, tag in next, tags do
		local line = lines[#lines] or label

		if not start and #line > Configuration.optionValue("ESPSplitLineLength") then
			lines[#lines + 1] = tag
			continue
		end

		line = line .. " " .. tag

		lines[start and 1 or #lines] = line

		start = false
	end

	return table.concat(lines, "\n")
end

---Update PositionESP.
---@param position Vector3
---@param tags string[]
function PositionESP:update(position, tags)
	local label = self.label
	local identifier = self.identifier

	if not Configuration.idToggleValue(identifier, "Enable") then
		return self:setVisible(false)
	end

	local camera = workspace.CurrentCamera
	local distance = (camera.CFrame.Position - position).Magnitude

	if distance > Configuration.idOptionValue(identifier, "MaxDistance") then
		return self:hide()
	end

	local screenPosition, onScreen = camera:WorldToViewportPoint(position)
	if not onScreen then
		return self:hide()
	end

	if Configuration.idToggleValue(identifier, "ShowDistance") then
		label = ESP_DISTANCE_FORMAT:format(label, distance)
	end

	local text = self:getDrawing("baseText")
	text:set("Text", self:build(label, tags))
	text:set("Position", Vector2.new(screenPosition.X, screenPosition.Y))
	text:set("Color", Configuration.idOptionValue(identifier, "Color"))
	text:set("Size", Configuration.optionValue("FontSize"))
	text:set("Visible", true)
	text:font(Configuration.optionValue("Font"))
end

---Setup drawings of PositionESP.
function PositionESP:setupDrawings()
	local baseText = self:createDrawing("baseText", { type = "Text", color = Color3.fromHex("FFFFFF") })
	baseText:set("Size", 14)
	baseText:set("Center", true)
	baseText:set("Outline", true)
	baseText:font("Plex")
end

---Create new PositionESP object.
---@param identifier string
---@param label string
function PositionESP.new(identifier, label)
	local self = setmetatable(DrawingPool.new(), PositionESP)
	self.label = label
	self.delayTimestamp = nil
	self.identifier = identifier
	self:setupDrawings()
	return self
end

-- Return PositionESP module.
return PositionESP
