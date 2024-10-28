-- Anything related to leaving a server is handled here.
local ServerLeaving = {}

---@module Utility.SendInput
local SendInput = require("Utility/SendInput")

-- Services.
local memStorageService = game:GetService("MemStorageService")
local guiService = game:GetService("GuiService")
local starterGui = game:GetService("StarterGui")
local coreGui = game:GetService("CoreGui")
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Block first avaliable user.
local function blockFirstAvaliableUser()
	local localPlayer = playersService.LocalPlayer

	for _, player in next, playersService:GetPlayers() do
		if player == localPlayer then
			continue
		end

		if pcall(localPlayer.IsFriendsWith, localPlayer, player.UserId) then
			continue
		end

		local oldBlockUserIds = starterGui:GetCore("GetBlockedUserIds")

		guiService:ClearError()

		while task.wait() do
			if #starterGui:GetCore("GetBlockedUserIds") ~= #oldBlockUserIds then
				break
			end

			starterGui:SetCore("PromptBlockPlayer", player)

			local robloxGui = coreGui:FindFirstChild("RobloxGui")
			if not robloxGui then
				continue
			end

			local promptDialog = robloxGui:FindFirstChild("PromptDialog")
			if not promptDialog then
				continue
			end

			local containerFrame = promptDialog:FindFirstChild("ContainerFrame")
			if not containerFrame then
				continue
			end

			local confirmButton = containerFrame:FindFirstChild("ConfirmButton")
			if not confirmButton then
				continue
			end

			local confirmScreenPosition = confirmButton.AbsolutePosition + Vector2.new(40, 40)

			SendInput.mb1(confirmScreenPosition.X, confirmScreenPosition.Y, 1)
		end

		break
	end
end

---Log from a server to leave.
function ServerLeaving.log()
	local requests = replicatedStorage:WaitForChild("Requests")
	local returnToMenu = requests:WaitForChild("ReturnToMenu")

	returnToMenu:FireServer()

	local localPlayer = playersService.LocalPlayer
	local choicePrompt = localPlayer.PlayerGui:WaitForChild("ChoicePrompt")
	local choice = choicePrompt and choicePrompt:WaitForChild("Choice")

	if not choicePrompt or not choice then
		return
	end

	choice:FireServer(true)
end

---Hop from a server to leave.
function ServerLeaving.hop()
	local localPlayer = playersService.LocalPlayer

	memStorageService:SetItem("ServerHop", localPlayer:GetAttribute("DataSlot"))
	memStorageService:SetItem("ServerHopJobId", Options.ServerHopJobId.Value)

	if Toggles.BlockUser.Value then
		blockFirstAvaliableUser()
	end

	ServerLeaving.log()
end

-- Return ServerLeaving module.
return ServerLeaving
