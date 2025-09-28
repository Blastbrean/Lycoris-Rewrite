return LPH_NO_VIRTUALIZE(function()
	-- Animation visualizer module.
	---@note: This code is UI code. It is ugly on purpose and lazily made.
	local AnimationVisualizer = {}

	---@module Features.Combat.Defense
	local Defense = require("Features/Combat/Defense")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module GUI.Library
	local Library = require("GUI/Library")

	---@module Utility.CoreGuiManager
	local CoreGuiManager = require("Utility/CoreGuiManager")

	-- Visualizer maid.
	local visualizerMaid = Maid.new()

	-- Services.
	local runService = game:GetService("RunService")
	local userInputService = game:GetService("UserInputService")
	local players = game:GetService("Players")

	local screenGui = CoreGuiManager.imark(Instance.new("ScreenGui"))
	screenGui.Name = "ScreenGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false

	local outer = Instance.new("Frame")
	outer.Name = "Outer"
	outer.BackgroundColor3 = Color3.new(1, 1, 1)
	outer.Position = UDim2.new(0.27, 0, 0.216, 0)
	outer.BorderColor3 = Color3.new()
	outer.Size = UDim2.new(0, 260, 0, 301.75)
	outer.ZIndex = 100
	outer.Parent = screenGui

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundColor3 = Library.MainColor
	inner.BorderMode = Enum.BorderMode.Inset
	inner.BorderColor3 = Library.OutlineColor
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.Parent = outer

	local animationVisualizer = Instance.new("TextLabel")
	animationVisualizer.Name = "AnimationVisualizer"
	animationVisualizer.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	animationVisualizer.TextColor3 = Library.AccentColor
	animationVisualizer.Text = "Animation Visualizer"
	animationVisualizer.BackgroundColor3 = Color3.new()
	animationVisualizer.BorderSizePixel = 0
	animationVisualizer.BackgroundTransparency = 1
	animationVisualizer.Position = UDim2.new(0, 5, 0, 5)
	animationVisualizer.TextXAlignment = Enum.TextXAlignment.Left
	animationVisualizer.BorderColor3 = Color3.new()
	animationVisualizer.TextSize = 17
	animationVisualizer.Size = UDim2.new(1, 0, 0, 20)
	animationVisualizer.Parent = inner

	local sliderOuter = Instance.new("Frame")
	sliderOuter.Name = "SliderOuter"
	sliderOuter.BackgroundColor3 = Color3.new(1, 1, 1)
	sliderOuter.Position = UDim2.new(0.323, -78, 0.835, 24)
	sliderOuter.BorderColor3 = Color3.new()
	sliderOuter.BorderSizePixel = 0
	sliderOuter.Size = UDim2.new(0, 247, 0, 15)
	sliderOuter.Parent = inner

	local sliderText = Instance.new("TextLabel")
	sliderText.Name = "SliderText"
	sliderText.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	sliderText.TextColor3 = Library.FontColor
	sliderText.Text = "0.000 / ? (?ms)"
	sliderText.BackgroundTransparency = 1
	sliderText.BackgroundColor3 = Color3.new(1, 1, 1)
	sliderText.BorderSizePixel = 0
	sliderText.BorderColor3 = Color3.new()
	sliderText.TextSize = 12
	sliderText.ZIndex = 12
	sliderText.Size = UDim2.new(1, 0, 1, 0)
	sliderText.Parent = sliderOuter

	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "SliderFill"
	sliderFill.BorderMode = Enum.BorderMode.Inset
	sliderFill.BorderColor3 = Library.AccentColorDark
	sliderFill.BackgroundColor3 = Library.AccentColor
	sliderFill.Size = UDim2.new(0, 1, 1, 0)
	sliderFill.ZIndex = 10
	sliderFill.Parent = sliderOuter

	local hideBorderRight = Instance.new("Frame")
	hideBorderRight.Name = "HideBorderRight"
	hideBorderRight.BackgroundColor3 = Library.AccentColor
	hideBorderRight.Position = UDim2.new(1, 0, 0, 0)
	hideBorderRight.BorderColor3 = Color3.new()
	hideBorderRight.BorderSizePixel = 0
	hideBorderRight.Size = UDim2.new(0, 1, 1, 0)
	hideBorderRight.Parent = sliderFill
	hideBorderRight.Visible = false

	local sliderInner = Instance.new("Frame")
	sliderInner.Name = "SliderInner"
	sliderInner.BorderColor3 = Color3.new()
	sliderInner.BackgroundColor3 = Library.MainColor
	sliderInner.Size = UDim2.new(1, 0, 1, 0)
	sliderInner.Parent = sliderOuter

	local frameBackwards = Instance.new("TextButton")
	frameBackwards.Name = "FrameBackwards"
	frameBackwards.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	frameBackwards.TextColor3 = Color3.new()
	frameBackwards.Text = ""
	frameBackwards.Position = UDim2.new(0.323, -78, 0.835, -2)
	frameBackwards.BackgroundColor3 = Library.MainColor
	frameBackwards.BorderColor3 = Color3.new()
	frameBackwards.TextSize = 14
	frameBackwards.Size = UDim2.new(0, 70, 0, 20)
	frameBackwards.Parent = inner

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.ScaleType = Enum.ScaleType.Crop
	icon.BorderColor3 = Color3.new()
	icon.BackgroundColor3 = Library.FontColor
	icon.Image = "rbxassetid://10734961526"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0.5, -8, 0.5, -8)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeXX
	icon.BorderSizePixel = 0
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.Parent = frameBackwards

	local playStop = Instance.new("TextButton")
	playStop.Name = "PlayStop"
	playStop.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	playStop.TextColor3 = Color3.new()
	playStop.BorderColor3 = Color3.new()
	playStop.Text = ""
	playStop.Position = UDim2.new(0.323, 0, 0.835, -2)
	playStop.BackgroundColor3 = Library.MainColor
	playStop.TextSize = 14
	playStop.Size = UDim2.new(0, 91, 0, 20)
	playStop.Parent = inner

	local iconTwo = Instance.new("ImageLabel")
	iconTwo.Name = "Icon"
	iconTwo.BorderColor3 = Color3.new()
	iconTwo.BackgroundColor3 = Library.FontColor
	iconTwo.Image = "rbxassetid://10734919336"
	iconTwo.BackgroundTransparency = 1
	iconTwo.Position = UDim2.new(0.5, -8, 0.5, -8)
	iconTwo.SizeConstraint = Enum.SizeConstraint.RelativeXX
	iconTwo.BorderSizePixel = 0
	iconTwo.Size = UDim2.new(0, 16, 0, 16)
	iconTwo.Parent = playStop

	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "ViewportFrame"
	viewportFrame.Visible = false
	viewportFrame.BorderMode = Enum.BorderMode.Inset
	viewportFrame.LightColor = Color3.new(0.549, 0.525, 0.435)
	viewportFrame.Ambient = Color3.new(0.318, 0.318, 0.318)
	viewportFrame.Position = UDim2.new(0, 4, 0, 26)
	viewportFrame.BackgroundColor3 = Library.MainColor
	viewportFrame.BorderColor3 = Color3.new()
	viewportFrame.Size = UDim2.new(1, -8, 0, 195)
	viewportFrame.Parent = inner

	local worldModel = Instance.new("WorldModel", viewportFrame)

	local camera = Instance.new("Camera", viewportFrame)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 70

	local speedText = Instance.new("TextLabel")
	speedText.Name = "SpeedText"
	speedText.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	speedText.TextColor3 = Library.FontColor
	speedText.Text = "Speed (???)"
	speedText.BackgroundTransparency = 1
	speedText.BackgroundColor3 = Color3.new(1, 1, 1)
	speedText.BorderSizePixel = 0
	speedText.BorderColor3 = Color3.new()
	speedText.TextSize = 12
	speedText.Size = UDim2.new(0, 82, 0, 20)
	speedText.ZIndex = 19
	speedText.Parent = viewportFrame

	local noViewportFrame = Instance.new("Frame")
	noViewportFrame.Name = "NoViewportFrame"
	noViewportFrame.BackgroundColor3 = Library.MainColor
	noViewportFrame.Position = UDim2.new(0, 4, 0, 26)
	noViewportFrame.BorderColor3 = Color3.new()
	noViewportFrame.BorderMode = Enum.BorderMode.Inset
	noViewportFrame.Size = UDim2.new(1, -8, 0, 195)
	noViewportFrame.Parent = inner

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	textLabel.TextColor3 = Library.FontColor
	textLabel.BorderColor3 = Color3.new()
	textLabel.Text = "Unknown Error"
	textLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	textLabel.BorderSizePixel = 0
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.new(0.0968, 0, 0.369, 0)
	textLabel.TextWrapped = true
	textLabel.TextSize = 14
	textLabel.Size = UDim2.new(0, 200, 0, 50)
	textLabel.Parent = noViewportFrame

	local color = Instance.new("Frame")
	color.Name = "Color"
	color.BackgroundColor3 = Library.AccentColor
	color.BorderColor3 = Color3.new()
	color.BorderSizePixel = 0
	color.Size = UDim2.new(1, 0, 0, 2)
	color.Parent = inner

	local frameForwards = Instance.new("TextButton")
	frameForwards.Name = "FrameForwards"
	frameForwards.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	frameForwards.TextColor3 = Color3.new()
	frameForwards.Text = ""
	frameForwards.Position = UDim2.new(0.323, 99, 0.835, -2)
	frameForwards.BackgroundColor3 = Library.MainColor
	frameForwards.BorderColor3 = Color3.new()
	frameForwards.TextSize = 14
	frameForwards.Size = UDim2.new(0, 69, 0, 20)
	frameForwards.Parent = inner

	local iconThree = Instance.new("ImageLabel")
	iconThree.Name = "Icon"
	iconThree.ScaleType = Enum.ScaleType.Crop
	iconThree.BorderColor3 = Color3.new()
	iconThree.BackgroundColor3 = Library.FontColor
	iconThree.Image = "rbxassetid://10734961809"
	iconThree.BackgroundTransparency = 1
	iconThree.Position = UDim2.new(0.5, -8, 0.5, -8)
	iconThree.SizeConstraint = Enum.SizeConstraint.RelativeXX
	iconThree.BorderSizePixel = 0
	iconThree.Size = UDim2.new(0, 16, 0, 16)
	iconThree.Parent = frameForwards

	local animationTextbox = Instance.new("TextBox")
	animationTextbox.Name = "AnimationTextbox"
	animationTextbox.CursorPosition = -1
	animationTextbox.TextColor3 = Library.FontColor
	animationTextbox.Text = "rbxassetid://0"
	animationTextbox.BackgroundColor3 = Library.MainColor
	animationTextbox.Position = UDim2.new(0.323, -78, 0.835, -24)
	animationTextbox.BorderColor3 = Color3.new()
	animationTextbox.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	animationTextbox.TextSize = 14
	animationTextbox.Size = UDim2.new(0, 246, 0, 15)
	animationTextbox.Parent = inner

	-- Current data for playback loop.
	local currentPlaybackData = nil
	local currentTrack = nil
	local isPaused = false
	local timeElapsed = 0.0

	---Map slider value.
	---@param value number
	---@param min number
	---@param max number
	---@param minSize number
	---@param maxSize number
	local function mapSliderValue(value, min, max, minSize, maxSize)
		return (1 - ((value - min) / (max - min))) * minSize + ((value - min) / (max - min)) * maxSize
	end

	---On Animation ID focus lost.
	---@param enter boolean
	---@param _ InputObject
	local function onIdFocusLost(enter, _)
		if not enter then
			return
		end

		-- Empty out previous data.
		currentTrack = nil
		currentPlaybackData = nil

		---@type PlaybackData
		local playbackData = Defense.agpd(animationTextbox.Text)
		if not playbackData then
			return AnimationVisualizer.message("No Playback Data Found")
		end

		-- Remove all previously loaded models.
		for _, descendant in next, viewportFrame:GetDescendants() do
			if descendant.ClassName ~= "Model" then
				continue
			end

			descendant:Destroy()
		end

		-- Load the model & center it.
		local entity = playbackData.entity:Clone()
		entity.Parent = worldModel
		entity:PivotTo(CFrame.new(0, 0, 0))

		-- Fetch the primary part. If it does not exist, then the entity has been unloaded.
		if not entity.PrimaryPart then
			return AnimationVisualizer.message("No Primary Part Found")
		end

		-- Setup camera.
		local _, bbs = entity:GetBoundingBox()
		camera.CFrame =
			CFrame.lookAt(entity.PrimaryPart.Position - Vector3.new(0, 0, bbs.Magnitude), entity.PrimaryPart.Position)

		-- Fetch animator.
		local animator = entity:FindFirstChildWhichIsA("Animator", true)
		if not animator then
			return AnimationVisualizer.message("No Animator Found")
		end

		-- Stop previous animations.
		for _, track in next, animator:GetPlayingAnimationTracks() do
			track:Stop()
		end

		-- Create animation.
		local animation = Instance.new("Animation")
		animation.AnimationId = animationTextbox.Text

		-- Store current data for playback.
		currentPlaybackData = playbackData
		currentTrack = animator:LoadAnimation(animation)

		-- Play animation and keep it at zero speed.
		currentTrack:Play(0.0, 100, 0.0)
		currentTrack.Priority = Enum.AnimationPriority.Action
		currentTrack.Looped = true
		visualizerMaid:mark(currentTrack.DidLoop:Connect(function()
			timeElapsed = 0.0
		end))

		-- Reset time elapsed.
		timeElapsed = 0.0

		-- Show frames.
		viewportFrame.Visible = true
		noViewportFrame.Visible = false
	end

	---Get time elapsed from time position.
	---@param timePosition number
	---@param animationLength number
	---@return number?
	local function getTimeElapsedFromTp(timePosition, animationLength)
		if not currentPlaybackData then
			return nil
		end

		if timePosition <= 0 then
			return 0.0
		end

		-- Numerical integration to find elapsed time.
		local currentPos = 0
		local elapsed = 0
		local dt = 0.01
		local iterations = 0

		while currentPos < timePosition do
			local speed = currentPlaybackData:last(elapsed) or 1
			local stepSize = speed * dt

			iterations = iterations + 1

			---@note: We can calculate how many iterations this should likely take based on the length (e.g 4 seconds) of the animation.
			--- Since we have a delta time of 0.01s, that means we can multiply the length by 100 to get our iteration amount.
			--- Then, we should multiply that number by 10 to act as a buffer. At minimum, we'll allow for 1000 iterations.
			if iterations >= math.max(((animationLength * 100) * 10), 1000) then
				break
			end

			-- If adding the full step would exceed the target position, calculate partial step and break.
			if currentPos + stepSize > timePosition then
				local remainingTime = (timePosition - currentPos) / speed
				elapsed = elapsed + remainingTime
				break
			end

			currentPos = currentPos + stepSize
			elapsed = elapsed + dt
		end

		-- Return the elapsed time.
		return elapsed
	end

	---On playback loop.
	---@param delta number
	local function onPlaybackLoop(delta)
		if not screenGui.Enabled then
			return
		end

		iconTwo.Image = isPaused and "rbxassetid://10734923549" or "rbxassetid://10734919336"

		-- Run slider calculations.
		local mhs = sliderOuter.AbsoluteSize.X
		local hs = currentTrack and mapSliderValue(currentTrack.TimePosition, 0.0, currentTrack.Length, 0, mhs) or 0.0

		-- Update slider text.
		sliderText.Text = (currentTrack and currentPlaybackData)
				and string.format(
					"%.3f/%.3f (%ims)",
					currentTrack.TimePosition,
					currentTrack.Length,
					math.round((getTimeElapsedFromTp(currentTrack.TimePosition, currentTrack.Length) or 0.0) * 1000)
				)
			or "0.000 / ??? (???ms)"

		-- Update size.
		sliderFill.Visible = not (hs == 0)
		sliderFill.Size = UDim2.new(0, math.max(math.ceil(hs), 1), 1, 0)
		hideBorderRight.Visible = not (hs == mhs or hs == 0)

		-- Update speed amount.
		speedText.Text = currentTrack and string.format("Speed (%.2f)", currentTrack.Speed) or "Speed (???)"

		if currentTrack and isPaused then
			speedText.Text = string.format(
				"Speed (%.2f)",
				currentPlaybackData:last(getTimeElapsedFromTp(currentTrack.TimePosition, currentTrack.Length) or 0.0)
					or 0.0
			)
		end

		if not currentTrack or not currentPlaybackData then
			return
		end

		if isPaused then
			return currentTrack:AdjustSpeed(0.0)
		end

		timeElapsed = timeElapsed + delta

		currentTrack:AdjustSpeed(currentPlaybackData:last(timeElapsed) or 0.0)
	end

	---Toggle play stop function.
	local function togglePlayStop()
		if not currentTrack then
			return
		end

		if not currentTrack.IsPlaying then
			return
		end

		isPaused = not isPaused
	end

	---Go backwards one frame.
	local function onFrameBackwards()
		if not currentTrack then
			return
		end

		currentTrack.TimePosition = math.max(currentTrack.TimePosition - 0.01, 0)
	end

	---Go forwards one frame.
	local function onFrameForwards()
		if not currentTrack then
			return
		end

		currentTrack.TimePosition = math.min(currentTrack.TimePosition + 0.01, currentTrack.Length)
	end

	---On slider input began.
	---@param input InputObject
	---@param gameProcessed boolean
	local function onSliderInputBegan(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		while screenGui.Enabled and userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
			if not currentTrack then
				return
			end

			-- Pause track.
			isPaused = true

			-- Calculate new time position.
			local mouse = players.LocalPlayer:GetMouse()
			local sliderOuterSize = sliderOuter.AbsoluteSize.X
			local mouseX = math.clamp(mouse.X - sliderOuter.AbsolutePosition.X, 0, sliderOuterSize)
			local newTimePosition = mapSliderValue(mouseX, 0, sliderOuterSize, 0, currentTrack.Length)

			-- Update time position.
			currentTrack.TimePosition = newTimePosition

			-- Wait.
			runService.PreRender:Wait()
		end

		timeElapsed = getTimeElapsedFromTp(currentTrack.TimePosition, currentTrack.Length) or 0.0
	end

	---Outer input began.
	---@param input InputObject
	---@param gameProcessed boolean
	local function outerFrameInputBegan(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space then
			return togglePlayStop()
		end

		if input.KeyCode == Enum.KeyCode.Right then
			return onFrameForwards()
		end

		if input.KeyCode == Enum.KeyCode.Left then
			return onFrameBackwards()
		end
	end

	---Set the visibility of the AnimationVisualizer.
	---@param state boolean
	function AnimationVisualizer.visible(state)
		screenGui.Enabled = state
	end

	---Show a message.
	---@param message string
	function AnimationVisualizer.message(message)
		viewportFrame.Visible = false
		noViewportFrame.Visible = true
		textLabel.Text = message
	end

	---Initialize AnimationVisualizer module.
	function AnimationVisualizer.init()
		-- Initialize GUI.
		screenGui.Name = "AnimationVisualizer"
		screenGui.Enabled = false
		screenGui.DisplayOrder = 1

		-- Make draggable.
		Library:MakeDraggable(outer)

		-- Setup colors.
		Library:AddToRegistry(color, {
			BackgroundColor3 = "AccentColor",
		}, true)

		Library:AddToRegistry(animationVisualizer, {
			TextColor3 = "AccentColor",
		}, true)

		Library:AddToRegistry(hideBorderRight, {
			BackgroundColor3 = "AccentColor",
		}, true)

		Library:AddToRegistry(sliderFill, {
			BackgroundColor3 = "AccentColor",
		}, true)

		Library:AddToRegistry(inner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		}, true)

		Library:AddToRegistry(playStop, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(animationTextbox, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
			TextColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(icon, {
			ImageColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(iconTwo, {
			ImageColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(iconThree, {
			ImageColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(textLabel, {
			TextColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(speedText, {
			TextColor3 = "FontColor",
		}, true)

		Library:AddToRegistry(noViewportFrame, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(frameBackwards, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(frameForwards, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(viewportFrame, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(sliderOuter, {
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(sliderInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "Black",
		}, true)

		Library:AddToRegistry(sliderFill, {
			BackgroundColor3 = "AccentColor",
			BorderColor3 = "AccentColorDark",
		}, true)

		Library:AddToRegistry(hideBorderRight, {
			BackgroundColor3 = "AccentColor",
		}, true)

		Library:AddToRegistry(sliderText, {
			TextColor3 = "FontColor",
		}, true)

		-- Setup camera.
		viewportFrame.CurrentCamera = camera

		-- Setup intro scene.
		AnimationVisualizer.message("Waiting For Animation ID")

		-- Setup signals.
		local idFocusLost = Signal.new(animationTextbox.FocusLost)
		local preRender = Signal.new(runService.PreRender)
		local playStopClicked = Signal.new(playStop.MouseButton1Click)
		local outerInputBegan = Signal.new(outer.InputBegan)
		local frameBackwardsClick = Signal.new(frameBackwards.MouseButton1Click)
		local frameForwardsClick = Signal.new(frameForwards.MouseButton1Click)
		local sliderInputBegan = Signal.new(sliderOuter.InputBegan)

		visualizerMaid:add(sliderInputBegan:connect("AnimationVisualizer_SliderInputBegan", onSliderInputBegan))
		visualizerMaid:add(frameForwardsClick:connect("AnimationVisualizer_FrameForwardsClick", onFrameForwards))
		visualizerMaid:add(frameBackwardsClick:connect("AnimationVisualizer_FrameBackwardsClick", onFrameBackwards))
		visualizerMaid:add(outerInputBegan:connect("AnimationVisualizer_OuterInputBegan", outerFrameInputBegan))
		visualizerMaid:add(playStopClicked:connect("AnimationVisualizer_PlayStopClicked", togglePlayStop))
		visualizerMaid:add(preRender:connect("AnimationVisualizer_PlaybackLoop", onPlaybackLoop))
		visualizerMaid:add(idFocusLost:connect("AnimationVisualizer_IdFocusLost", onIdFocusLost))

		-- Add outer frame to library.
		Library.AnimationVisualizerFrame = outer
	end

	---Detach AnimationVisualizer module.
	function AnimationVisualizer.detach()
		visualizerMaid:clean()
	end

	-- Return AnimationVisualizer module.
	return AnimationVisualizer
end)()
