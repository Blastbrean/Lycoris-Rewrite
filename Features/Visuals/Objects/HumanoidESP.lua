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
	if not humanoid then
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
		return self:setVisible(false)
	end

	local viewportPosition, viewPortOnScreen = currentCamera:WorldToViewportPoint(position)
	local headPosition, headOnScreen = currentCamera:WorldToViewportPoint(position + Vector3.new(0, 3, 0))

	if not viewPortOnScreen and not headOnScreen then
		return self:setVisible(false)
	end

	local text = self:getDrawing("baseText")
	text:set("Position", Vector2.new(headPosition.X, headPosition.Y))
	text:set("Text", self.nameCallback(self, humanoid, distance))
	text:set("Size", Configuration.expectOptionValue("ESPFontSize"))
	text:set("Font", Drawing.Fonts[Configuration.expectOptionValue("ESPFont")])
	text:set("Color", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "Color")))
	text:set("Visible", true)

	local frustrumHeight = math.tan(math.rad(currentCamera.FieldOfView * 0.5)) * 2 * viewportPosition.Z
	local healthBarSize = currentCamera.ViewportSize.Y / frustrumHeight * Vector2.new(4, 4)

	local viewportScreenPos = Vector2.new(viewportPosition.X, viewportPosition.Y)
	local healthBarFrom = viewportScreenPos - (healthBarSize * 0.5) - Vector2.xAxis * 5
	local healthBarTo = viewportScreenPos - (healthBarSize * Vector2.new(0.5, -0.5)) - Vector2.xAxis * 5

	local healthBarOutline = self:getDrawing("healthBarOutline")
	healthBarOutline:set("Visible", Configuration.expectToggleValue(VisualsTab.identify(self.identifier, "HealthBar")))
	healthBarOutline:set("Thickness", 123 / distance + 2)
	healthBarOutline:set("From", healthBarFrom - Vector2.yAxis)
	healthBarOutline:set("To", healthBarTo + Vector2.yAxis)

	local healthPercentage = humanoid.Health / humanoid.MaxHealth

	local healthBar = self:getDrawing("healthBar")
	healthBar:set("Thickness", 123 / distance + 1)
	healthBar:set("Visible", healthBarOutline:get("Visible"))
	healthBar:set("From", healthBarOutline:get("To"))
	healthBar:set("To", healthBarOutline:get("To"):Lerp(healthBarOutline:get("From"), healthPercentage))
	healthBar:set("Color", Color3.new(1, 0.2, 0.2):Lerp(Color3.new(0.2, 1, 0.45), healthPercentage))
end

---Setup drawings of basic esp.
function HumanoidESP:setupDrawings()
	local healthBarOutline = self:createDrawing("healthBarOutline", {
		type = "Line",
		color = Color3.fromHex("000000"),
	})

	local healthBar = self:createDrawing("healthBar", {
		type = "Line",
		color = Color3.fromHex("000000"),
	})

	healthBarOutline:set("Thickness", 16)
	healthBar:set("Thickness", 14)
end

---Create new HumanoidESP object.
---@param identifier string
---@param instance Instance
---@param nameCallback function
function HumanoidESP.new(identifier, instance, nameCallback)
	local self = setmetatable(BasicESP.new(identifier, instance, nameCallback), HumanoidESP)
	self:setupDrawings()
	return self
end

-- Return HumanoidESP module.
return HumanoidESP
