---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@class EntityESP
local EntityESP = {}
EntityESP.__index = EntityESP
EntityESP.__type = "EntityESP"

-- Services.
local playersService = game:GetService("Players")

-- Constants.
local ELEMENT_PADDING = 1
local BILLBOARD_MIN_WIDTH = 10
local BILLBOARD_MIN_HEIGHT = 10

---Give an inside outline to a frame.
---@param frame Frame
---@param strokeColor Color3
---@param insideOffset number
EntityESP.gio = LPH_NO_VIRTUALIZE(function(frame, strokeColor, insideOffset)
	local sizeOffset = -insideOffset * 2
	local strokeContainer = Instance.new("Frame")
	strokeContainer.Name = "Outline_" .. tostring(insideOffset)
	strokeContainer.Parent = frame
	strokeContainer.Size = UDim2.new(1, sizeOffset, 1, sizeOffset)
	strokeContainer.Position = UDim2.new(0, insideOffset, 0, insideOffset)
	strokeContainer.BackgroundTransparency = 1

	local outlineStroke = Instance.new("UIStroke")
	outlineStroke.Color = strokeColor
	outlineStroke.Thickness = 1
	outlineStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	outlineStroke.Parent = strokeContainer

	return strokeContainer
end)

---Update text.
---@param self EntityESP
---@param container Frame
---@param text string
EntityESP.utext = LPH_NO_VIRTUALIZE(function(self, container, text)
	local textLabel = container:FindFirstChildOfClass("TextLabel")
	if not textLabel then
		return
	end

	textLabel.Text = text
	textLabel.TextSize = Configuration.expectOptionValue("FontSize")
	textLabel.Font = Enum.Font[Configuration.expectOptionValue("Font")] or Enum.Font.Code
	textLabel.TextColor3 = Configuration.idOptionValue(self.identifier, "Color")
end)

---Get bar in container.
EntityESP.gb = LPH_NO_VIRTUALIZE(function(container)
	local background = container:FindFirstChild("Background")
	if not background then
		return nil
	end

	local barArea = background:FindFirstChild("BarArea")
	if not barArea then
		return nil
	end

	local bar = barArea:FindFirstChild("Bar")
	if not bar then
		return nil
	end

	return bar
end)

---Modify bar size.
---@param container Frame
---@param vertical boolean
---@param percentage number
EntityESP.mbs = LPH_NO_VIRTUALIZE(function(container, vertical, percentage)
	local background = container:FindFirstChild("Background")
	if not background then
		return
	end

	local barArea = background:FindFirstChild("BarArea")
	if not barArea then
		return
	end

	local bar = barArea:FindFirstChild("Bar")
	if not bar then
		return
	end

	percentage = math.clamp(percentage, 0.0, 1.0)

	if vertical then
		bar.Size = UDim2.new(1, 0, percentage, 0)
	else
		bar.Size = UDim2.new(percentage, 0, 1, 0)
	end
end)

---Create a generic bar.
---@param container Frame
---@param vertical boolean
---@param seperators boolean
---@param color Color3
EntityESP.cgb = LPH_NO_VIRTUALIZE(function(self, container, seperators, vertical, color)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Parent = container

	if vertical then
		background.Size = UDim2.new(1, -1, -1, 0)
		background.Position = UDim2.new(1, -1, 1, 0)
		background.AnchorPoint = Vector2.new(1.0, 0.0)
	else
		background.Size = UDim2.new(1, 0, 1, 0)
		background.Position = UDim2.new(0, 0, 0, 0)
		background.AnchorPoint = Vector2.new(0, 0)
	end

	background.BackgroundColor3 = Color3.new(0.0862745, 0.105882, 0.219608)
	background.BorderSizePixel = 0

	self.gio(background, Color3.new(0, 0, 0), 0)

	local barArea = Instance.new("Frame")
	barArea.Name = "BarArea"
	barArea.Parent = background
	barArea.BackgroundTransparency = 1
	barArea.Position = UDim2.new(0, 1, 0, 1)
	barArea.Size = UDim2.new(1, -2, 1, -2)

	-- separators only for vertical bars (to match original visual)
	if seperators then
		for Idx = 1, 4 do
			local Separator = Instance.new("Frame")
			Separator.Name = "Separator"
			Separator.Parent = barArea
			Separator.BackgroundColor3 = Color3.new(0, 0, 0)
			Separator.BorderSizePixel = 0
			Separator.Position = UDim2.new(0, 0, Idx / 5, 0)
			Separator.Size = UDim2.new(1, 0, 0, 1)
			Separator.ZIndex = 2
		end
	end

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Parent = barArea
	bar.BorderSizePixel = 0

	if vertical then
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.new(0, 0, 1, 0)
		bar.Size = UDim2.new(1, 0, 0.0, 0)
	else
		bar.Position = UDim2.new(0, 0, 0, 0)
		bar.Size = UDim2.new(0.0, 0, 1, 0)
	end

	bar.BackgroundColor3 = color
end)

---Set visibility.
---@param visible boolean
EntityESP.visible = LPH_NO_VIRTUALIZE(function(self, visible)
	self.billboard.Enabled = visible
end)

---Detach InstanceESP.
EntityESP.detach = LPH_NO_VIRTUALIZE(function(self)
	self.maid:clean()
end)

---Update seperators.
---@param self EntityESP
---@param distance number
EntityESP.useperators = LPH_NO_VIRTUALIZE(function(self, distance)
	local bar = self.gb(self.hbar)
	if not bar then
		return
	end

	local seperators = bar.Parent:GetChildren()

	for _, sep in next, seperators do
		if not sep:IsA("Frame") then
			continue
		end

		if sep.Name ~= "Separator" then
			continue
		end

		sep.Visible = distance <= 300
	end
end)

---Build text.
---@param self EntityESP
---@param label string
---@param tags string[]
---@return string, number
EntityESP.btext = LPH_NO_VIRTUALIZE(function(self, label, tags)
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

	return table.concat(lines, "\n"), #lines
end)

---Update InstanceESP.
---@param self InstanceESP
---@param tags string[]
EntityESP.update = LPH_NO_VIRTUALIZE(function(self, tags)
	local identifier = self.identifier

	-- Perform basic validation.
	local localPlayer = playersService.LocalPlayer
	local localCharacter = localPlayer and localPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

	local entityHumanoid = self.entity and self.entity:FindFirstChildOfClass("Humanoid")
	local entityRoot = self.entity and self.entity:FindFirstChild("HumanoidRootPart")
	local position = entityRoot and entityRoot.Position

	if not Configuration.idToggleValue(identifier, "Enable") then
		return self:visible(false)
	end

	if not entityHumanoid then
		return self:visible(false)
	end

	if not localRoot then
		return self:visible(false)
	end

	if not position then
		return self:visible(false)
	end

	local distance = (localRoot.Position - position).Magnitude

	if distance > Configuration.idOptionValue(identifier, "MaxDistance") then
		return self:visible(false)
	end

	-- Update Adornee.
	self.billboard.Adornee = entityRoot

	-- Update element visibility.
	local bbstroke = self.bbstroke
	local wbstroke = self.wbstroke
	local dcontainer = self.dcontainer
	local ncontainer = self.ncontainer
	local hbar = self.hbar

	bbstroke.Visible = Configuration.idToggleValue(identifier, "BoundingBox")
	wbstroke.Visible = Configuration.idToggleValue(identifier, "BoundingBox")
	dcontainer.Visible = Configuration.idToggleValue(identifier, "ShowDistance")
	hbar.Visible = Configuration.idToggleValue(identifier, "HealthBar")

	-- Update element information.
	local text, lines = self:btext(self.label, tags)
	self:utext(ncontainer, text)

	local name = self:find("Name")
	if name then
		name.space = (lines * Configuration.expectOptionValue("FontSize")) + (ELEMENT_PADDING * 2)
	end

	local delement = self:find("Distance")
	if delement then
		delement.space = Configuration.expectOptionValue("FontSize") + (ELEMENT_PADDING * 2)
	end

	if dcontainer then
		self:utext(dcontainer, string.format("%im", math.floor(distance)))
	end

	-- Get bar.
	local bar = self.gb(hbar)

	if hbar and bar then
		-- Percentage.
		local percent = entityHumanoid.Health / entityHumanoid.MaxHealth
		local fullColor = Configuration.idOptionValue(identifier, "FullColor")
		local emptyColor = Configuration.idOptionValue(identifier, "EmptyColor")

		-- Update sizing.
		self.mbs(hbar, true, percent)

		-- Update color.
		bar.BackgroundColor3 = emptyColor:Lerp(fullColor, math.clamp(percent, 0.0, 1.0))

		-- Update seperators.
		self:useperators(distance)
	end

	-- Build layout.
	self:build()

	-- Set visible.
	self:visible(true)
end)

---Build EntityESP layout.
EntityESP.build = LPH_NO_VIRTUALIZE(function(self)
	-- Calculate total thickness added to each side.
	local sideOffsets = { top = 0, bottom = 0, left = 0, right = 0 }

	for side, elementList in next, self.elements do
		local offsetElementCount = 0

		-- Add up space for each element on this side.
		for _, item in next, elementList do
			if not item.container.Visible then
				continue
			end

			sideOffsets[side] = sideOffsets[side] + item.space + ELEMENT_PADDING
			offsetElementCount = offsetElementCount + 1
		end

		-- Remove trailing padding if we offset any elements.
		if offsetElementCount > 0 then
			sideOffsets[side] = sideOffsets[side] - ELEMENT_PADDING
		end
	end

	-- Determine the "max" padding needed to keep things symmetrical.
	local maxHorizontalPadding = math.max(sideOffsets.left, sideOffsets.right)
	local maxVerticalPadding = math.max(sideOffsets.top, sideOffsets.bottom)

	-- Scale the BillboardGUI accordingly.
	if not self.sextents then
		local fmodel = self.entity:Clone()

		for _, inst in next, fmodel:GetDescendants() do
			if inst:IsA("BasePart") then
				continue
			end

			inst:Destroy()
		end

		self.sextents = fmodel:GetExtentsSize()
	end

	self.billboard.Size = UDim2.new(
		self.sextents.X + 1.5,
		maxHorizontalPadding * 2 + BILLBOARD_MIN_WIDTH,
		self.sextents.Y + 1.5,
		maxVerticalPadding * 2 + BILLBOARD_MIN_HEIGHT
	)

	-- Position the bounding box in the exact center of our symmetrical GUI.
	self.bbox.Position = UDim2.new(0, maxHorizontalPadding, 0, maxVerticalPadding)
	self.bbox.Size = UDim2.new(1, -(maxHorizontalPadding * 2), 1, -(maxVerticalPadding * 2))

	-- 1. Stacking upwards from the box (top elements).
	local currentTopOffset = 0

	for _, element in next, self.elements.top do
		if not element.container.Visible then
			continue
		end

		element.container.Parent = self.canvas
		element.container.AnchorPoint = Vector2.new(0, 1)
		element.container.Position = UDim2.new(0, maxHorizontalPadding, 0, maxVerticalPadding - currentTopOffset)
		element.container.Size = UDim2.new(1, -(maxHorizontalPadding * 2), 0, element.space)
		currentTopOffset = currentTopOffset + element.space + ELEMENT_PADDING

		if element.created then
			continue
		end

		if not element.create then
			continue
		end

		element.create(element.container)
		element.created = true
	end

	-- 2. Stacking downwards from the box (bottom elements).
	local currentBottomOffset = 0

	for _, element in next, self.elements.bottom do
		if not element.container.Visible then
			continue
		end

		element.container.Parent = self.bbox
		element.container.AnchorPoint = Vector2.new(0, 0)
		element.container.Position = UDim2.new(0, 0, 1, currentBottomOffset)
		element.container.Size = UDim2.new(1, 0, 0, element.space)
		currentBottomOffset = currentBottomOffset + element.space + ELEMENT_PADDING

		if element.created then
			continue
		end

		if not element.create then
			continue
		end

		element.create(element.container)
		element.created = true
	end

	-- 3. Stacking to the left from the box (left elements).
	local currentLeftOffset = 0

	for _, element in next, self.elements.left do
		if not element.container.Visible then
			continue
		end

		element.container.Parent = self.canvas
		element.container.AnchorPoint = Vector2.new(1, 0)
		element.container.Position = UDim2.new(0, maxHorizontalPadding - currentLeftOffset, 0, maxVerticalPadding)
		element.container.Size = UDim2.new(0, element.space, 1, -(maxVerticalPadding * 2))
		currentLeftOffset = currentLeftOffset + element.space + ELEMENT_PADDING

		if element.created then
			continue
		end

		if not element.create then
			continue
		end

		element.create(element.container)
		element.created = true
	end

	-- 4. Stacking to the right from the box (right elements).
	local currentRightOffset = 0

	for _, element in next, self.elements.right do
		if not element.container.Visible then
			continue
		end

		element.container.Parent = self.bbox
		element.container.AnchorPoint = Vector2.new(0, 0)
		element.container.Position = UDim2.new(1, currentRightOffset, 0, 0)
		element.container.Size = UDim2.new(0, element.space, 1, 0)
		currentRightOffset = currentRightOffset + element.space + ELEMENT_PADDING

		if element.created then
			continue
		end

		if not element.create then
			continue
		end

		element.create(element.container)
		element.created = true
	end
end)

---Find an element with a given name.
---@param name string
EntityESP.find = LPH_NO_VIRTUALIZE(function(self, name)
	for _, list in next, self.elements do
		for _, element in next, list do
			if element.name ~= name then
				continue
			end

			return element
		end
	end

	return nil
end)

---Add new element(s) to EntityESP.
---@param name string
---@param side string "Top" | "Bottom" | "Left" | "Right"
---@param space number
---@param create function
EntityESP.add = LPH_NO_VIRTUALIZE(function(self, name, side, space, create)
	local container = Instance.new("Frame")
	container.Name = string.format("%s_Container_%s", side, name)
	container.BackgroundTransparency = 1

	table.insert(self.elements[side], {
		name = name,
		container = container,
		space = space,
		create = create,
		created = false,
	})

	return container
end)

---Add extra elements. Override me.
EntityESP.extra = LPH_NO_VIRTUALIZE(function(_) end)

---Setup EntityESP.
EntityESP.setup = LPH_NO_VIRTUALIZE(function(self)
	local root = self.entity:FindFirstChild("HumanoidRootPart")

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.AlwaysOnTop = true
	billboardGui.Enabled = false
	billboardGui.Adornee = root or self.entity
	billboardGui.Parent = workspace
	billboardGui.ClipsDescendants = false
	billboardGui.AutoLocalize = false

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.BackgroundTransparency = 1
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.Position = UDim2.new(0, 0, 0, 0)
	canvas.Parent = billboardGui

	local espBoundingBox = Instance.new("Frame")
	espBoundingBox.Name = "ESPBoundingBox"
	espBoundingBox.Parent = canvas
	espBoundingBox.BackgroundTransparency = 1
	espBoundingBox.Size = UDim2.new(1, 0, 1, 0)
	espBoundingBox.Position = UDim2.new(0, 0, 0, 0)

	-- Box outlines. We cannot set visible to the frame directly, we must hide these two if we don't want bounding boxes.
	self.bbstroke = self.gio(espBoundingBox, Color3.new(0, 0, 0), 0)
	self.wbstroke = self.gio(espBoundingBox, Color3.new(1, 1, 1), 1)

	-- Setup main instances.
	self.billboard = self.maid:mark(billboardGui)
	self.canvas = self.maid:mark(canvas)
	self.bbox = self.maid:mark(espBoundingBox)

	-- Add elements.
	self.hbar = self:add("HealthBar", "left", 6, function(container)
		self:cgb(container, true, true, Color3.new(1.0, 1.0, 1.0))
	end)

	self:extra()

	self.dcontainer = self:add("Distance", "bottom", 16, function(container)
		local textLabel = Instance.new("TextLabel")
		textLabel.Parent = container
		textLabel.Text = "0m"
		textLabel.Size = UDim2.new(0, 400, 1, 0)
		textLabel.AnchorPoint = Vector2.new(0.5, 0)
		textLabel.Position = UDim2.new(0.5, 0, 0, 0)
		textLabel.BackgroundTransparency = 1.0
		textLabel.TextStrokeColor3 = Color3.new(0.0, 0.0, 0.0)
		textLabel.TextStrokeTransparency = 0.0
		textLabel.TextColor3 = Color3.new(1.0, 1.0, 1.0)
		textLabel.TextSize = 13
		textLabel.TextWrapped = false
		textLabel.Font = Enum.Font.Code
	end)

	self.ncontainer = self:add("Name", "top", 16, function(container)
		local textLabel = Instance.new("TextLabel")
		textLabel.Parent = container
		textLabel.Text = "N/A"
		textLabel.Size = UDim2.new(0, 400, 1, 0)
		textLabel.AnchorPoint = Vector2.new(0.5, 0)
		textLabel.Position = UDim2.new(0.5, 0, 0, 0)
		textLabel.BackgroundTransparency = 1.0
		textLabel.TextStrokeColor3 = Color3.new(0.0, 0.0, 0.0)
		textLabel.TextStrokeTransparency = 0.0
		textLabel.TextColor3 = Color3.new(0.0117647, 1, 1)
		textLabel.TextSize = 13
		textLabel.TextWrapped = false
		textLabel.Font = Enum.Font.Code
	end)
end)

---Create new EntityESP object. Caller is responsible for setup and update.
---@param entity Model
---@param identifier string
---@param label string
function EntityESP.new(entity, identifier, label)
	local self = setmetatable({}, EntityESP)
	self.label = label
	self.entity = entity
	self.identifier = identifier
	self.maid = Maid.new()
	self.elements = {
		top = {},
		bottom = {},
		left = {},
		right = {},
	}

	return self
end

-- Return EntityESP module.
return EntityESP
