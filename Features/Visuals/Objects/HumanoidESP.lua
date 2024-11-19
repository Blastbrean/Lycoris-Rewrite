---@module Features.Visuals.Objects.BasicESP
local BasicESP = require("Features/Visuals/Objects/BasicESP")

---@module Menu.VisualsTab
local VisualsTab = require("Menu/VisualsTab")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

---@class HumanoidESP: BasicESP
local HumanoidESP = setmetatable({}, { __index = BasicESP })
HumanoidESP.__index = HumanoidESP

---Update humanoid esp.
function HumanoidESP:update()
	if not Configuration.expectToggleValue(VisualsTab.identify(self.identifier, "Enable")) then
		return self:setVisible(false)
	end

	local parent = self.instance.Parent
	if not parent then
		return self:setVisible(false)
	end

	local humanoid = self.instance:FindFirstChildOfClass("Humanoid")
	local rootPart = self.instance:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return self:setVisible(false)
	end

	local position = Vector3.zero

	if self.usePivot then
		position = self.instance:GetPivot().Position
	elseif self.usePosition then
		position = self.instance.Position
	end

	local currentCamera = workspace.CurrentCamera
	local distance = (currentCamera.CFrame.Position - position).Magnitude

	if distance > Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "DistanceThreshold")) then
		if Configuration.expectToggleValue("ESPCheckDelayIgnoreHumanoid") then
			return self:setVisible(false)
		else
			return self:setInvisibleAndDelayUpdate()
		end
	end

	local headPosition, headOnScreen = currentCamera:WorldToViewportPoint(position + Vector3.new(0, 3, 0))

	if not headOnScreen then
		if Configuration.expectToggleValue("ESPCheckDelayIgnoreHumanoid") then
			return self:setVisible(false)
		else
			return self:setInvisibleAndDelayUpdate()
		end
	end

	local text = self:getDrawing("baseText")
	text:set("Position", Vector2.new(headPosition.X, headPosition.Y))
	text:set("Text", self.nameCallback(self, humanoid, distance))
	text:set("Size", Configuration.expectOptionValue("ESPFontSize"))
	text:set("Font", Drawing.Fonts[Configuration.expectOptionValue("ESPFont")])
	text:set("Color", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "Color")))
	text:set("Visible", true)
end

---Create new HumanoidESP object.
---@param identifier string
---@param instance Instance
---@param nameCallback function
function HumanoidESP.new(identifier, instance, nameCallback)
	return setmetatable(BasicESP.new(identifier, instance, nameCallback), HumanoidESP)
end

-- Return HumanoidESP module.
return HumanoidESP
