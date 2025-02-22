return LPH_NO_VIRTUALIZE(function()
	-- Attributes module for handling attribute related functions.
	local Attributes = {}

	---Is the user not at the specified stat cap yet?
	---@param playerCharacter Model
	---@param attribute string
	---@param cap string
	---@return boolean
	function Attributes.isNotAtCap(playerCharacter, attribute, cap)
		local useDefault = cap == ""
		local maxStat = useDefault and 100 or tonumber(cap)
		local statCap = maxStat == 0 and 100 or maxStat

		local currentStat = tonumber(playerCharacter:GetAttribute(attribute) or 0)
		if not currentStat or currentStat >= statCap then
			return false
		end

		return true
	end

	-- Return AttributeFarm module
	return Attributes
end)()
