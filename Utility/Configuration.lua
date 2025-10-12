-- Safe configuration getter methods.
-- The menu is the last thing initialized in the script.
local Configuration = {}

---Expect toggle value.
---@param key string
---@return any?
Configuration.expectToggleValue = LPH_NO_VIRTUALIZE(function(key)
	if not Toggles then
		return nil
	end

	local toggle = Toggles[key]

	if not toggle then
		return nil
	end

	return toggle.Value
end)

---Expect option value.
---@param key string
---@return any?
Configuration.expectOptionValue = LPH_NO_VIRTUALIZE(function(key)
	if not Options then
		return nil
	end

	local option = Options[key]

	if not option then
		return nil
	end

	return option.Value
end)

---Expect option values.
---@param key string
---@return any?
Configuration.expectOptionValues = LPH_NO_VIRTUALIZE(function(key)
	if not Options then
		return nil
	end

	local option = Options[key]

	if not option then
		return nil
	end

	return option.Values
end)

---Identify element.
---@param identifier string
---@param topLevelIdentifier string
---@return string
Configuration.identify = LPH_NO_VIRTUALIZE(function(identifier, topLevelIdentifier)
	return identifier .. topLevelIdentifier
end)

---Fetch toggle value.
---@param identifier string
---@param topLevelIdentifier string
---@return any
Configuration.idToggleValue = LPH_NO_VIRTUALIZE(function(identifier, topLevelIdentifier)
	if not Toggles then
		return nil
	end

	local toggle = Toggles[identifier .. topLevelIdentifier]
	if not toggle then
		return nil
	end

	return toggle.Value
end)

---Fetch option value.
---@param identifier string
---@param topLevelIdentifier string
---@return any
Configuration.idOptionValue = LPH_NO_VIRTUALIZE(function(identifier, topLevelIdentifier)
	if not Options then
		return nil
	end

	local option = Options[identifier .. topLevelIdentifier]
	if not option then
		return nil
	end

	return option.Value
end)

---Fetch option values.
---@param identifier string
---@param topLevelIdentifier string
---@return any
Configuration.idOptionValues = LPH_NO_VIRTUALIZE(function(identifier, topLevelIdentifier)
	if not Options then
		return nil
	end

	local option = Options[identifier .. topLevelIdentifier]
	if not option then
		return nil
	end

	return option.Values
end)

-- Return Configuration module.
return Configuration
