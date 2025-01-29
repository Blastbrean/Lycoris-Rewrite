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

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local ownershipMaid = Maid.new()
local partMaid = Maid.new()

-- Ownership data.
local clientPart = Instance.new('Part', workspace)
local clientPeerId = gethiddenproperty(clientPart, "NetworkOwnerV3")
clientPart:Destroy()

---Check for network ownership. Fallback to legacy check if NetworkOwnerV3 is not available.
---@param part BasePart
---@return boolean
local function hasNetworkOwnership(part)
    local success, partPeerId = pcall(function()
        return gethiddenproperty(part, "NetworkOwnerV3")
    end)

    if not success then
        return not part.Anchored and part.ReceiveAge == 0 and part.AssemblyLinearVelocity.Magnitude > 0
    end

    return partPeerId == clientPeerId
end

---Add live characters to ownership watcher.
---@param character Model
local function onLiveAdded(character)
    if not character:IsA('Model') then
        return
    end

    if OwnershipWatcher.modelsToScan[character] then
        return
    end

    OwnershipWatcher.modelsToScan[character] = true
end

---Remove live characters from ownership watcher.
---@param character Model
local function onLiveRemoved(character)
    if not OwnershipWatcher.modelsToScan[character] then
        return
    end

    OwnershipWatcher.modelsToScan[character] = nil

    partMaid:clean()
end

---Update ownership.
local function updateOwnership()
    ---@optimization: Stop updating when we don't need it.
    if not Configuration.expectToggleValue("ShowOwnership") and not Configuration.expectToggleValue("VoidMobs") then
        return
    end

    for model, _ in next, OwnershipWatcher.modelsToScan do
        local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            continue
        end

        -- Check if owner.
        local isNetworkOwner = hasNetworkOwnership(humanoidRootPart)

        -- Visualization.
        local netVisual = InstanceWrapper.create(partMaid, "NetworkVisual", "Part", model)
        netVisual.Anchored = true
        netVisual.CanCollide = false
        netVisual.Size = Vector3.new(5, 5, 2)
        netVisual.Transparency = Configuration.expectToggleValue("ShowOwnership") and 0.8 or 1.0
        netVisual.Color = isNetworkOwner and  Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        netVisual.CFrame = humanoidRootPart.CFrame

        -- Mark part.
        OwnershipWatcher.parts[humanoidRootPart] = { owned = isNetworkOwner, model = model }
    end
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
end

---Detach OwnershipWatcher module.
function OwnershipWatcher.detach()
    ownershipMaid:clean()
end

-- Return OwnershipWatcher module.
return OwnershipWatcher