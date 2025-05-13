-- Ownership data.
local clientPart = Instance.new("Part", workspace)
local clientPeerId = gethiddenproperty(clientPart, "NetworkOwnerV3")
clientPart:Destroy()

---Check for network ownership. Fallback to legacy check if NetworkOwnerV3 is not available.
---@note: Currently, as of 3/14, this check has been broken by Roblox.
---@note: If we're using AWP, we can simply use their *good* ownership function.
---@param part BasePart
---@return boolean
local function hasNetworkOwnership(part)
	if getexecutorname():match("AWP") then
		return isnetworkowner(part)
	end

	local success, partPeerId = pcall(function()
		return gethiddenproperty(part, "NetworkOwnerV3")
	end)

	if not success then
		return not part:IsGrounded() and part.AssemblyRootPart.ReceiveAge == 0
	end

	return partPeerId == clientPeerId
end

return LPH_NO_VIRTUALIZE(function()
	-- Ownership watcher module.
	local OwnershipWatcher = { modelsToScan = {}, parts = {} }

	-- Services
	local runService = game:GetService("RunService")

	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.InstanceWrapper
	local InstanceWrapper = require("Utility/InstanceWrapper")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	---@module Utility.OriginalStoreManager
	local OriginalStoreManager = require("Utility/OriginalStoreManager")

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)

	-- Maids.
	local ownershipMaid = Maid.new()

	---Clean up parts. Every model to scan has a maid linked to it.
	local function cleanParts()
		for _, maid in next, OwnershipWatcher.modelsToScan do
			maid:clean()
		end
	end

	---Add live characters to ownership watcher.
	---@param character Model
	local function onLiveAdded(character)
		if not character:IsA("Model") then
			return
		end

		if OwnershipWatcher.modelsToScan[character] then
			return
		end

		OwnershipWatcher.modelsToScan[character] = Maid.new()
	end

	---Remove live characters from ownership watcher.
	---@param character Model
	local function onLiveRemoved(character)
		if not OwnershipWatcher.modelsToScan[character] then
			return
		end

		OwnershipWatcher.modelsToScan[character]:clean()
		OwnershipWatcher.modelsToScan[character] = nil
	end

	---Update ownership.
	local function updateOwnership()
		---@optimization: Stop updating when we don't need it.
		if not Configuration.expectToggleValue("ShowOwnership") and not Configuration.expectToggleValue("VoidMobs") then
			return cleanParts()
		end

		-- Create an update table.
		local updateTable = {}

		-- Add models.
		for model, maid in next, OwnershipWatcher.modelsToScan do
			local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				continue
			end

			-- Check if owner.
			local isNetworkOwner = hasNetworkOwnership(humanoidRootPart)

			-- Visualization.
			local netVisual = InstanceWrapper.create(maid, "NetworkVisual", "Part", model)
			netVisual.Size = Vector3.new(10, 10, 10)
			netVisual.Transparency = Configuration.expectToggleValue("ShowOwnership") and 0.8 or 1.0
			netVisual.Color = isNetworkOwner and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
			netVisual.CFrame = humanoidRootPart.CFrame
			netVisual.Anchored = true
			netVisual.CanCollide = false

			-- Part data.
			local data = OwnershipWatcher.parts[humanoidRootPart]
				or {
					owned = isNetworkOwner,
					model = model,
					map = OriginalStoreManager.new(),
				}

			-- Update part data.
			data.owned = isNetworkOwner
			data.model = model

			-- Set in global part list.
			OwnershipWatcher.parts[humanoidRootPart] = data

			-- Set in map.
			updateTable[humanoidRootPart] = data
		end

		-- Override global part list with the new update table.
		---@note: This will get rid of any parts that were not updated (e.g no longer existing root part or not in model list) upon cycle.
		---@todo: Fix me - this is a bit of a hack.
		OwnershipWatcher.parts = updateTable
	end

	---Get table of watched parts along with a mapping to extra data.
	---@return table<BasePart, table>
	function OwnershipWatcher.get()
		return OwnershipWatcher.parts
	end

	---Iniitalize OwnershipWatcher module.
	function OwnershipWatcher.init()
		local live = workspace:WaitForChild("Live")
		local liveChildAdded = Signal.new(live.ChildAdded)
		local liveChildRemoved = Signal.new(live.ChildRemoved)

		ownershipMaid:add(liveChildAdded:connect("OwnershipWatcher_OnLiveChildAdded", onLiveAdded))
		ownershipMaid:add(liveChildRemoved:connect("OwnershipWatcher_OnLiveChildRemoved", onLiveRemoved))
		ownershipMaid:add(renderStepped:connect("OwnershipWatcher_RenderStepped", updateOwnership))

		for _, entity in next, live:GetChildren() do
			onLiveAdded(entity)
		end

		Logger.warn("OwnershipWatcher initialized.")
	end

	---Detach OwnershipWatcher module.
	function OwnershipWatcher.detach()
		-- Clean up ownership maids.
		ownershipMaid:clean()

		-- Clean up parts.
		cleanParts()

		-- Log.
		Logger.warn("OwnershipWatcher detached.")
	end

	-- Return OwnershipWatcher module.
	return OwnershipWatcher
end)()
