-- Safe configuration getter methods.
-- The menu is the last thing initialized in the script.
local Configuration = {}

---Expect toggle value.
---@param key string
---@return any?
function Configuration.expectToggleValue(key)
	if not Toggles then
		return nil
	end

	local toggle = Toggles[key]

	if not toggle then
		return nil
	end

	return toggle.Value
end

---Expect option value.
---@param key string
---@return any?
function Configuration.expectOptionValue(key)
	if not Options then
		return nil
	end

	local option = Options[key]

	if not option then
		return nil
	end

	return option.Value
end

-- Return Configuration module.
return Configuration
