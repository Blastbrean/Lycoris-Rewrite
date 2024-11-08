-- Features related stuff is handled here.
local Features = {}

---@module Features.Automation.AstralFarm
local AstralFarm = require("Features/Automation/AstralFarm")

---@module Features.Automation.MaestroFarm
local MaestroFarm = require("Features/Automation/MaestroFarm")

---@module Features.Automation.CharismaFarm
local CharismaFarm = require("Features/Automation/CharismaFarm")

---@module Features.Automation.InteligenceFarm
local IntelligenceFarm = require("Features/Automation/InteligenceFarm")

---@module Features.Player.Movement
local Movement = require("Features/Player/Movement")

---@module Features.Player.Removal
local Removal = require("Features/Player/Removal")

---@module Features.Player.Exploits
local Exploits = require("Features/Player/Exploits")

---Initialize features.
function Features.init()
	AstralFarm.init()
	MaestroFarm.init()
	CharismaFarm.init()
	IntelligenceFarm.init()
	Movement.init()
	Removal.init()
	Exploits.init()
end

---Detach features.
function Features.detach()
	AstralFarm.detach()
	MaestroFarm.detach()
	CharismaFarm.detach()
	IntelligenceFarm.detach()
	Movement.detach()
	Removal.detach()
	Exploits.detach()
end

-- Return Features module.
return Features
