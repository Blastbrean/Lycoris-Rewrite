---@module Utility.DrawingPool
local DrawingPool = require("Utility/DrawingPool")

---@module Menu.VisualsTab
local VisualsTab = require("Menu/VisualsTab")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

---@class BasicESP: DrawingPool
---@field identifier string
---@field instance Instance
local BasicESP = setmetatable({}, { __index = DrawingPool })
BasicESP.__index = BasicESP

---Update basic esp.
function BasicESP:update()
	if not Configuration.expectToggleValue(VisualsTab.identify(self.identifier, "Enable")) then
		return self:setVisible(false)
	end

	local parent = self.instance.Parent
	if not parent then
		return self:setVisible(false)
	end

	local position = Vector3.zero

	if self.usePivot then
		position = self.instance:GetPivot()
	elseif self.usePosition then
		position = self.instance.Position
	end

	local currentCamera = workspace.CurrentCamera
	local distance = (currentCamera.CFrame.Position - position).Magnitude

	if distance > Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "DistanceThreshold")) then
		return self:setVisible(false)
	end

	local headPosition, onScreen = currentCamera:WorldToViewportPoint(position + Vector3.new(0, 3, 0))

	if not onScreen then
		return self:setVisible(false)
	end

	local text = self:getDrawing("baseText")
	text:set("Position", headPosition)
	text:set("Text", self.nameCallback(self, distance, parent))
	text:set("Color", Options[VisualsTab.identify(self.identifier, "Color")].Value)
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
