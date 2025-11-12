-- LycorisTab module.
local LycorisTab = {}

---@module GUI.ThemeManager
local ThemeManager = require("GUI/ThemeManager")

---@module GUI.SaveManager
local SaveManager = require("GUI/SaveManager")

---@module GUI.Library
local Library = require("GUI/Library")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---Initialize Cheat Settings section.
---@param groupbox table
function LycorisTab.initCheatSettingsSection(groupbox)
	groupbox:AddButton("Toggle Silent Mode", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Lycoris.silent = not shared.Lycoris.silent

		if not shared.Lycoris.silent then
			Logger.notify("Silent mode was disabled.")
		end

		if isfile("smarker.txt") then
			delfile("smarker.txt")
		else
			writefile(
				"smarker.txt",
				"Hello, if you're reading this, that means you have Lycoris-Rewrite (Deepwoken) silent mode turned on. Deleting this file will turn it off."
			)
		end
	end)

	groupbox:AddButton("Toggle Player Scanning", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Lycoris.dpscanning = not shared.Lycoris.dpscanning

		if shared.Lycoris.dpscanning then
			Logger.notify("Player scanning was disabled.")
		else
			Logger.notify("Player scanning was enabled.")
		end

		if isfile("dpscanning.txt") then
			delfile("dpscanning.txt")
		else
			writefile(
				"dpscanning.txt",
				"Hello, if you're reading this, that means you have Lycoris-Rewrite (Deepwoken) player scanning turned off. Deleting this file will turn it on."
			)
		end
	end)

	groupbox:AddButton("Toggle Bloxstrap RPC", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Lycoris.norpc = not shared.Lycoris.norpc

		if not shared.Lycoris.norpc then
			Logger.notify("Bloxstrap RPC was enabled.")
		else
			Logger.notify("Bloxstrap RPC was disabled.")
		end

		if isfile("norpc.txt") then
			delfile("norpc.txt")
		else
			writefile(
				"norpc.txt",
				"Hello, if you're reading this, that means you have Lycoris-Rewrite (Deepwoken) Bloxstrap RPC turned off. Deleting this file will turn it on."
			)
		end
	end)

	groupbox:AddButton("Unload Cheat", function()
		shared.Lycoris.detach()
	end)
end

---Initialize UI Settings section.
---@param groupbox table
function LycorisTab.initUISettingsSection(groupbox)
	local menuBindLabel = groupbox:AddLabel("Menu Bind")

	menuBindLabel:AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu Keybind" })

	local keybindFrameLabel = groupbox:AddLabel("Keybind List Bind")

	keybindFrameLabel:AddKeyPicker("KeybindList", {
		Default = "N/A",
		Mode = "Off",
		NoUI = true,
		Text = "Keybind List",
		Callback = function(Value)
			Library.KeybindFrame.Visible = Value
		end,
	})

	local watermarkFrameLabel = groupbox:AddLabel("Watermark Bind")

	watermarkFrameLabel:AddKeyPicker("Watermark", {
		Default = "N/A",
		Mode = "Off",
		NoUI = true,
		Text = "Watermark",
		Callback = function(Value)
			Library:SetWatermarkVisibility(Value)
		end,
	})
end

---Initialize tab.
function LycorisTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Settings") -- dont change the name, it's more confusing if its named that way

	-- Initialize sections.
	LycorisTab.initCheatSettingsSection(tab:AddLeftGroupbox("Cheat Settings"))
	LycorisTab.initUISettingsSection(tab:AddRightGroupbox("UI Settings"))

	-- Configure SaveManager & ThemeManager.
	ThemeManager:ApplyToTab(tab)
	SaveManager:BuildConfigSection(tab)
end

-- Return LycorisTab module.
return LycorisTab
