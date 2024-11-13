-- Logger module.
local Logger = {}

---@module GUI.Library
local Library = require("GUI/Library")

---Build a string with a prefix.
---@param str string
---@return string
local function buildPrefixString(str)
	return string.format("[%s %s] [lycoris recode]: %s", os.date("%x"), os.date("%X"), str)
end

---Notify message with a default cooldown to create consistent cooldowns between files.
---@param str string
function Logger.notify(str, ...)
	Library:Notify(string.format(str, ...), 3.0)
end

---Warn message.
---@param str string
function Logger.warn(str, ...)
	warn(string.format(buildPrefixString(str), ...))
end

---Trace & warn message.
---@param str string
function Logger.trace(str, ...)
	Logger.warn(str, ...)
	warn(debug.traceback(2))
end

-- Return Logger module.
return Logger
