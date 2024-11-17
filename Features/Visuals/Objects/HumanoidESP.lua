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
		position = self.instance:GetPivot()
	elseif self.usePosition then
		position = self.instance.Position
	end

	local currentCamera = workspace.CurrentCamera
	local distance = (currentCamera.CFrame.Position - position).Magnitude

	if distance > Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "DistanceThreshold")) then
		return self:setVisible(false)
	end

	local headPosition, headOnScreen = currentCamera:WorldToViewportPoint(position + Vector3.new(0, 3, 0))
	local viewportPosition, viewPortOnScreen = currentCamera:WorldToViewportPoint(position)
	local legPosition, legOnScreen = currentCamera:WorldToViewportPoint(position - Vector3.new(0, 0.5, 0))

	if not headOnScreen or not viewPortOnScreen or not legOnScreen then
		return self:setVisible(false)
	end

	local text = self:getDrawing("baseText")
	text:set("Position", headPosition)
	text:set("Text", self.nameCallback(self, humanoid, distance))
	text:set("Color", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "Color")))
	text:set("Visible", true)

	local baseBox = self:getDrawing("baseBox")
	baseBox:set("Visible", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "Box")))
	baseBox:set("Color", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "BoxColor")))
	baseBox:set("Size", Vector2.new(1000 / viewportPosition.Z, headPosition.Y - legPosition.Y))
	baseBox:set(
		"Position",
		Vector2.new(viewportPosition.X - baseBox:get("Size").X / 2, viewportPosition.Y - baseBox:get("Size").Y / 2)
	)

	local frustrumHeight = math.tan(math.rad(currentCamera.FieldOfView * 0.5)) * 2 * viewportPosition.Z
	local healthBarSize = currentCamera.ViewportSize.Y / frustrumHeight * Vector2.new(4, 4)
	local healthBarOffset = (Vector2.new(viewportPosition.X, viewportPosition.Y) - healthBarSize * 0.5)
	local healthPercentage = humanoid.Health / humanoid.MaxHealth

	local healthBarOutline = self:getDrawing("healthBarOutline")
	healthBarOutline:set("Visible", Configuration.expectOptionValue(VisualsTab.identify(self.identifier, "HealthBar")))
	healthBarOutline:set("Thickness", 123 / distance + 2)
	healthBarOutline:set("From", ((healthBarOffset * 0.5) - Vector2.xAxis * 5) - Vector2.yAxis)
	healthBarOutline:set("To", (healthBarOffset * Vector2.new(0.5, -0.5)) + Vector2.yAxis)

	local healthBar = self:getDrawing("healthBar")
	healthBar:set("Thickness", 123 / distance + 1)
	healthBar:set("Visible", healthBarOutline:get("Visible"))
	healthBar:set("From", healthBarOutline:get("To"))
	healthBar:set("To", healthBarOutline:get("To"):Lerp(healthBarOutline:get("From"), healthPercentage))
	healthBar:set("Color", Color3.new(1, 0.2, 0.2):Lerp(Color3.new(0.2, 1, 0.45), healthPercentage))
end

---Setup drawings of basic esp.
function HumanoidESP:setupDrawings()
	local baseText = self:createDrawing("baseText", { type = "Text", color = Color3.fromHex("FFFFFF") })
	baseText:set("Size", 14)
	baseText:set("Center", true)
	baseText:set("Outline", true)
	baseText:set("Font", "Plex")

	local baseBox = self:createDrawing("baseBox", { type = "Square", color = Color3.fromHex("FFFFFF") })
	baseBox:set("Size", Vector2.new(40, 50))
	baseBox:set("Filled", false)

	local healthBarOutline = self:createDrawing("healthBarOutline", {
		type = "Square",
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
	return setmetatable(BasicESP.new(identifier, instance, nameCallback), HumanoidESP)
end

-- Return HumanoidESP module.
return HumanoidESP
