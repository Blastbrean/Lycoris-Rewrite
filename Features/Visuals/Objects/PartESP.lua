---@module Features.Visuals.Objects.InstanceESP
local InstanceESP = require("Features/Visuals/Objects/InstanceESP")

---@class PartESP: InstanceESP
---@field part Part
local PartESP = setmetatable({}, { __index = InstanceESP })
PartESP.__index = PartESP

---Update PartESP.
---@param tags string[]
PartESP.update = LPH_NO_VIRTUALIZE(function(self, tags)
	local part = self.part

	if not part.Parent then
		return self:visible(false)
	end

	InstanceESP.update(self, part.Position, tags or {})
end)

---Create new PartESP object.
---@param identifier string
---@param part Part
---@param label string
function PartESP.new(identifier, part, label)
	if not part:IsA("BasePart") then
		return error(string.format("PartESP expected part on %s creation.", identifier))
	end

	local self = setmetatable(InstanceESP.new(part, identifier, label), PartESP)
	self.part = part
	return self
end

-- Return PartESP module.
return PartESP
