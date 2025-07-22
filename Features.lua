-- Features related stuff is handled here.
local Features = {}

---@module Features.Automation.CharismaFarm
local CharismaFarm = require("Features/Automation/CharismaFarm")

---@module Features.Automation.InteligenceFarm
local IntelligenceFarm = require("Features/Automation/InteligenceFarm")

---@module Features.Game.Movement
local Movement = require("Features/Game/Movement")

---@module Features.Exploits.Exploits
local Exploits = require("Features/Exploits/Exploits")

---@module Features.Visuals.Visuals
local Visuals = require("Features/Visuals/Visuals")

---@module Features.Game.Removal
local Removal = require("Features/Game/Removal")

---@module Features.Game.Monitoring
local Monitoring = require("Features/Game/Monitoring")

---@module Features.Game.Spoofing
local Spoofing = require("Features/Game/Spoofing")

---@module Features.Game.Bestiary
local Bestiary = require("Features/Game/Bestiary")

---@module Features.Game.OwnershipWatcher
local OwnershipWatcher = require("Features/Game/OwnershipWatcher")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

---@module Features.Game.AnimationVisualizer
local AnimationVisualizer = require("Features/Game/AnimationVisualizer")

---@module Features.Automation.FishFarm
local FishFarm = require("Features/Automation/FishFarm")

---Initialize features.
---@note: Careful with features that have entire return LPH_NO_VIRTUALIZE(function() blocks. We assume that we don't care about what's placed in there.
function Features.init()
	Defense.init()
	Visuals.init()
	Movement.init()
	Monitoring.init()
	Removal.init()
	Exploits.init()
	Spoofing.init()
	Bestiary.init()
	OwnershipWatcher.init()
	CharismaFarm.init()
	IntelligenceFarm.init()
	FishFarm.init()

	-- Only initialize if we're a builder.
	if not armorshield or armorshield.current_role == "builder" then
		AnimationVisualizer.init()
	end

	Logger.warn("Features initialized.")
end

---Detach features.
function Features.detach()
	-- Only detach if we're a builder.
	if not armorshield or armorshield.current_role == "builder" then
		AnimationVisualizer.detach()
	end

	FishFarm.detach()
	Defense.detach()
	CharismaFarm.detach()
	IntelligenceFarm.detach()
	Spoofing.detach()
	Bestiary.detach()
	OwnershipWatcher.detach()
	Movement.detach()
	Removal.detach()
	Monitoring.detach()
	Exploits.detach()
	Visuals.detach()
	Logger.warn("Features detached.")
end

-- Return Features module.
return Features
