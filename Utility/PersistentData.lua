-- PersistentData module.
local PersistentData = {
	-- First Lycoris initialization.
	fli = os.clock(),

	-- Do we need to handle server hopping on initialization?
	sh = false,

	-- Specified Job ID for the hop?
	shjid = nil,

	-- Should we handle the start menu on initialization?
	hsm = false,
}
