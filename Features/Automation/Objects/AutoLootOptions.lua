---@class AutoLootOptions
---@field smin number Minimum stars to loot.
---@field smax number Maximum stars to loot.
---@field wanted string[] List of wanted item names.
---@field lall boolean Whether to loot everything.
local AutoLootOptions = {}

---Create new AutoLootOptions object.
---@param smin number Minimum stars to loot.
---@param smax number Maximum stars to loot.
---@param wanted string[] List of wanted item names.
---@param lall boolean Whether to loot everything.
---@return AutoLootOptions
function AutoLootOptions.new(smin, smax, wanted, lall)
	local self = setmetatable({}, AutoLootOptions)
	self.smin = smin
	self.smax = smax
	self.wanted = wanted
	self.lall = lall
	return self
end

-- Return AutoLootOptions module.
return AutoLootOptions
