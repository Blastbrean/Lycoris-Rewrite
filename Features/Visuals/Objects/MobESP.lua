---@module Features.Visuals.Objects.EntityESP
local EntityESP = require("Features/Visuals/Objects/EntityESP")

---@class MobESP: EntityESP
local MobESP = setmetatable({}, { __index = EntityESP })
MobESP.__index = MobESP
MobESP.__type = "MobESP"

-- Formats.
local ESP_HEALTH = "[%i/%i]"

---Update MobESP.
---@param self MobESP
MobESP.update = LPH_NO_VIRTUALIZE(function(self)
	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return self:visible(false)
	end

	EntityESP.update(self, { ESP_HEALTH:format(humanoid.Health, humanoid.MaxHealth) })
end)

---Create new MobESP object.
---@param identifier string
---@param model Model
---@param label string
function MobESP.new(identifier, model, label)
	local self = setmetatable(EntityESP.new(model, identifier, label), MobESP)
	self:setup()
	self:build()
	self:update()
	return self
end

-- Return MobESP module.
return MobESP
