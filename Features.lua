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

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

---Initialize features.
function Features.init()
	Defense.init()
	Visuals.init()
	Movement.init()
	Monitoring.init()
	Removal.init()
	Exploits.init()
	Spoofing.init()
	CharismaFarm.init()
	IntelligenceFarm.init()
	Logger.warn("Features initialized.")
end

---Detach features.
function Features.detach()
	Defense.detach()
	CharismaFarm.detach()
	IntelligenceFarm.detach()
	Spoofing.detach()
	Movement.detach()
	Removal.detach()
	Monitoring.detach()
	Exploits.detach()
	Visuals.detach()
	Logger.warn("Features detached.")
end

-- Return Features module.
return Features
