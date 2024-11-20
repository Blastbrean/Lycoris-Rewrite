---@module Utility.DrawingPool
local DrawingPool = require("Utility/DrawingPool")

---@module Menu.VisualsTab
local VisualsTab = require("Menu/VisualsTab")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

---@class BasicESP: DrawingPool
---@field identifier string
---@field instance Instance
---@field delayUpdate number?
local BasicESP = setmetatable({}, { __index = DrawingPool })
BasicESP.__index = BasicESP

---Set visibility off and delay the next update.
function BasicESP:setInvisibleAndDelayUpdate()
	if Configuration.expectToggleValue("ESPCheckDelay") then
		self.delayUpdate = os.clock() + (Configuration.expectOptionValue("ESPCheckDelayTime") or 1.0)
	end

	return self:setVisible(false)
end

---Update basic esp.
function BasicESP:update()
	local identifier = self.identifier
	local instance = self.instance

	if not Configuration.expectToggleValue(VisualsTab.identify(identifier, "Enable")) then
		return self:setVisible(false)
	end

	local parent = instance.Parent
	if not parent then
		return self:setVisible(false)
	end

	local position = Vector3.zero

	if self.usePivot then
		position = instance:GetPivot().Position
	elseif self.usePosition then
		position = instance.Position
	end

	local currentCamera = workspace.CurrentCamera
	local distance = (currentCamera.CFrame.Position - position).Magnitude

	if distance > Configuration.expectOptionValue(VisualsTab.identify(identifier, "DistanceThreshold")) then
		return self:setInvisibleAndDelayUpdate()
	end

	local instPosition, onScreen = currentCamera:WorldToViewportPoint(position)

	if not onScreen then
		return self:setInvisibleAndDelayUpdate()
	end

	local text = self:getDrawing("baseText")
	text:set("Position", Vector2.new(instPosition.X, instPosition.Y))
	text:set("Text", self.nameCallback(self, distance, parent))
	text:set("Size", Configuration.expectOptionValue("ESPFontSize"))
	text:set("Font", Drawing.Fonts[Configuration.expectOptionValue("ESPFont")])
	text:set("Color", Configuration.expectOptionValue(VisualsTab.identify(identifier, "Color")))
	text:set("Visible", true)
end

---Setup drawings of basic esp.
function BasicESP:setupDrawings()
	local baseText = self:createDrawing("baseText", { type = "Text", color = Color3.fromHex("FFFFFF") })
	baseText:set("Size", 14)
	baseText:set("Center", true)
	baseText:set("Outline", true)
	baseText:set("Font", "Plex")
end

---Create new BasicESP object.
---@param identifier string
---@param instance Instance
---@param nameCallback function
function BasicESP.new(identifier, instance, nameCallback)
	if not instance:IsA("Model") and not instance:IsA("BasePart") then
		return error("Invalid instance type.")
	end

	local self = setmetatable(DrawingPool.new(), BasicESP)
	self.usePivot = instance:IsA("Model")
	self.usePosition = instance:IsA("BasePart")
	self.identifier = identifier
	self.instance = instance
	self.nameCallback = nameCallback
	self:setupDrawings()

	return self
end

-- Return BasicESP module.
return BasicESP
