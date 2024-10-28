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

---Initialize features.
function Features.init()
	AstralFarm.init()
	MaestroFarm.init()
	CharismaFarm.init()
	IntelligenceFarm.init()
	Movement.init()
end

---Detach features.
function Features.detach()
	AstralFarm.detach()
	MaestroFarm.detach()
	CharismaFarm.detach()
	IntelligenceFarm.detach()
	Movement.detach()
end

-- Return Features module.
return Features
