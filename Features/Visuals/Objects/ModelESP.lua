---@module Features.Visuals.Objects.InstanceESP
local InstanceESP = require("Features/Visuals/Objects/InstanceESP")

---@class ModelESP: InstanceESP
---@field model Model
local ModelESP = setmetatable({}, { __index = InstanceESP })
ModelESP.__index = ModelESP

---Update ModelESP.
---@param tags string[]
ModelESP.update = LPH_NO_VIRTUALIZE(function(self, tags)
	local model = self.model

	if not model.Parent then
		return self:visible(false)
	end

	InstanceESP.update(self, model:GetPivot().Position, tags or {})
end)

---Create new ModelESP object.
---@param identifier string
---@param model Model
---@param label string
function ModelESP.new(identifier, model, label)
	if not model:IsA("Model") then
		return error(string.format("ModelESP expected model on %s creation.", identifier))
	end

	local self = setmetatable(InstanceESP.new(model, identifier, label), ModelESP)
	self.model = model
	self.model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	return self
end

-- Return ModelESP module.
return ModelESP
