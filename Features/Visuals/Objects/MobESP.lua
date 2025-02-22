---@module Features.Visuals.Objects.ModelESP
local ModelESP = require("Features/Visuals/Objects/ModelESP")

---@class MobESP: ModelESP
local MobESP = setmetatable({}, { __index = ModelESP })
MobESP.__index = MobESP

-- Formats.
local ESP_HEALTH = "[%i/%i]"

---Update MobESP.
MobESP.update = LPH_NO_VIRTUALIZE(function(self)
	local humanoid = self.model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return self:visible(false)
	end

	ModelESP.update(self, { ESP_HEALTH:format(humanoid.Health, humanoid.MaxHealth) })
end)

---Create new MobESP object.
---@param identifier string
---@param model Model
---@param label string
function MobESP.new(identifier, model, label)
	return setmetatable(ModelESP.new(identifier, model, label), MobESP)
end

-- Return MobESP module.
return MobESP
