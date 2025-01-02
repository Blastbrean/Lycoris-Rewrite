---@module Utility.Maid
local Maid = require("Utility/Maid")

-- Handle all defense related functions.
local Defense = {}

-- Maids.
local defenseMaid = Maid.new()

---Initialize defense.
function Defense.init() end

---Detach defense.
function Defense.detach()
	defenseMaid:clean()
end

-- Return Defense module.
return Defense
