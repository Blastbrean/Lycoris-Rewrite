-- Services
local runService = game:GetService("RunService")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local ownershipMaid = Maid.new()

--- Replication Part & PeerId
local clientPart = Instance.new('Part', workspace)
local PeerId = gethiddenproperty(clientPart, "NetworkOwnerV3")
clientPart:Destroy()

--- NetworkWatcher
local NetworkVisual = Instance.new('Part')
NetworkVisual.Anchored = false
NetworkVisual.CanCollide = false
NetworkVisual.Size = Vector3.new(5, 5, 2)
NetworkVisual.Transparency = 0.8
NetworkVisual.Color = Color3.fromRGB(0, 0, 255)
NetworkVisual.Name = "NetworkVisual"
Instance.new('Weld', NetworkVisual).Part1 = NetworkVisual

-- Ownership holder
local ownershipHolder = {}

---Check for network ownership (legacy)
---@param part BasePart
---@return boolean
local function legacyNetworkOwnership(part)
    return not part.Anchored and part.ReceiveAge == 0 and part.Velocity.Magnitude > 0
end

---Check for network ownership
---@param part BasePart
---@return boolean
local function hasNetworkOwnership(part)
    local success, ID = pcall(function()
        return gethiddenproperty(part, "NetworkOwnerV3")
    end)

    if not success then
        return legacyNetworkOwnership(part)
    end
    
    return ID == PeerId
end

---Add live Characters to ownership watcher
---@param character Model
local function onLiveAdded(character)
    if table.find(ownershipHolder, character) or not character:IsA('Model') then
        return
    end
    table.insert(ownershipHolder, character)
end

---Remove live Characters from ownership watcher
---@param character Model
local function onLiveRemoved(character)
    if not table.find(ownershipHolder, character) then
        return
    end
    table.remove(ownershipHolder, table.find(ownershipHolder, character))
end

local function updateOwnership()
    local ShowOwnership = Configuration.expectToggleValue("ShowOwnership")
    for _,v in next, ownershipHolder do
        local HumanoidRootPart = v:FindFirstChild("HumanoidRootPart")
        if not HumanoidRootPart then
            continue
        end

        local NetVisual = HumanoidRootPart:FindFirstChild("NetworkVisual")
        
        if not NetVisual and ShowOwnership then
            NetVisual = NetworkVisual:Clone()
            NetVisual.Weld.Part0 = HumanoidRootPart
            NetVisual.Parent = HumanoidRootPart
        end

        if not ShowOwnership and NetVisual then
            NetVisual:Destroy()
            continue
        end
        
        local isNetworkOwner = hasNetworkOwnership(HumanoidRootPart)
        if not isNetworkOwner then
            NetVisual.Color = Color3.fromRGB(0, 0, 255)
            v:RemoveTag('NetworkOwner')
            continue
        end

        NetVisual.Color = Color3.fromRGB(0, 255, 0)
        v:AddTag('NetworkOwner')
    end
end

local ownershipWatcher = {}

function ownershipWatcher.init()
	local live = workspace:WaitForChild("Live")
	local liveChildAdded = Signal.new(live.ChildAdded)
	local liveChildRemoved = Signal.new(live.ChildRemoved)

    ownershipMaid:add(liveChildAdded:connect("onLiveAdded_ChildAdded", onLiveAdded))
    ownershipMaid:add(liveChildRemoved:connect("onLiveAdded_ChildRemoved", onLiveRemoved))
    ownershipMaid:add(renderStepped:connect("updateOwnership_RenderStepped", updateOwnership))

    for _,v in next, live:GetChildren() do
        onLiveAdded(v)
    end
end

function ownershipWatcher.detach()
    ownershipMaid:clean()
end

return ownershipWatcher