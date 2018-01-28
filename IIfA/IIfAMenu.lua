--this creates a menu for the addon.
IIfA = IIfA

local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMediaProvider-1.0")

local function getCharacterInventories()
	
	local accountInventories = {}
	
	if nil ~= IIfA:GetCharacterList() then
		for characterName, character in pairs(IIfA:GetCharacterList()) do
			d("inserting " .. characterName)
			table.insert(accountInventories, characterName)
		end
	end
	
	return accountInventories
end

local function getGuildBanks()
	local guildBanks = {}
	if(IIfA.data.guildBanks) then
		for guildName, guildData in pairs(IIfA.data.guildBanks) do
			if guildData.bCollectData == nil then
				guildData.bCollectData = true
			end
			table.insert(guildBanks, guildName)
		end
	end
	return guildBanks
end

--[[checkboxData = {
	type = "checkbox",
	name = "My Checkbox", -- or string id or function returning a string
	getFunc = function() return db.var end,
	setFunc = function(value) db.var = value doStuff() end,
	tooltip = "Checkbox's tooltip text.", -- or string id or function returning a string (optional)
	width = "full", -- or "half" (optional)
	disabled = function() return db.someBooleanSetting end,	--or boolean (optional)
	warning = "Will need to reload the UI.", -- or string id or function returning a string (optional)
	default = defaults.var,	-- a boolean or function that returns a boolean (optional)
	reference = "MyAddonCheckbox", -- unique global reference to control (optional)
}	]]

local function getGuildBankName(guildNum)
	if guildNum > GetNumGuilds() then return end
	id = GetGuildId(guildNum)
	return GetGuildName(id)
end

local function getHouseNames()
	local ret = {}
	for houseName, houseId in pairs(IIfA:GetHouseList()) do
		if IIfA:GetTrackedBags()[houseId] then
			table.insert(ret, houseName)
		end
	end
	return ret
end

local function getIgnoredHouseNames()
	local ret = {}
	for houseName, houseId in pairs(IIfA:GetHouseList()) do
		if not IIfA:GetTrackedBags()[houseId] then
			table.insert(ret, houseName)
		end
	end
	return ret
end

local function getGuildBankKeepDataSetting(guildNum)
	guildName = getGuildBankName(guildNum)

	if IIfA.data.guildBanks[guildName] == nil then return false end

	if IIfA.data.guildBanks[guildName].bCollectData == nil then
		IIfA.data.guildBanks[guildName].bCollectData = true
	end

	return IIfA.data.guildBanks[guildName].bCollectData
end

local function setGuildBankKeepDataSetting(guildNum, newSetting)
	guildName = getGuildBankName(guildNum)
	if guildName ~= nil then
		IIfA.data.guildBanks[guildName].bCollectData = newSetting
	end
end

function IIfA:CreateOptionsMenu()
	local deleteChar, deleteGBank, undeleteChar

	local optionsData = {
		{	type = "header",
			name = "Global Settings",
		},
		{
			type = "checkbox",
			tooltip = "Should you really wish to move your window around a hundred times, uncheck this box",
			name = "Use same settings for all characters?",
			getFunc = function() return IIfA.data.saveSettingsGlobally end,
			setFunc = function(value)
				IIfA.data.saveSettingsGlobally = value
			end
		},
		{
			type = "checkbox",
			tooltip = "Prints verbose debugging to the ChatFrame. '/ii debug' for quick toggle",
			name = "Debugging",
			getFunc = function() return IIfA.data.bDebug end,
			setFunc = function(value) IIfA.data.bDebug = value end
		},

		{
			type = "submenu",
			name = "Manage Collected Data",
			tooltip = "Manage collected Characters and Guild Banks. Delete data you no longer need (old guilds or deleted characters)",	--(optional)
			controls = {
				{	type 	= "description", 
					title 	= "Ignore or delete characters",
					text 	= "removes or un-tracks a character. \nWarning: This change will be applied immediately.",
				},
				{
					type 	= "dropdown",
					name 	= "characters to delete or un-track",
					choices = IIfA:GetCharacterList(),
					getFunc = function() return end,
					setFunc = function(choice) deleteChar = nil; deleteChar = choice end
				}, --dropdown end

				{  -- button begin
					type = "button",
					width = "half",
					name = "Delete Character",
					tooltip = "Delete Inventory Insight data for the character selected above",
					func = function() IIfA:DeleteCharacterData(deleteChar) end,
				}, -- button end
				
				{  -- button begin
					type = "button",
					width = "half",
					name = "Ignore Equipment",
					tooltip = "All items equipped by the current character will be ignored",
					func = function() IIfA:IgnoreCharacterEquip(deleteChar, true) end,

				}, -- button end
				{  -- button begin
					type = "button",
					width = "half",
					name = "Ignore Inventory",
					tooltip = "This character's carried inventory will be ignored",
					func = function() IIfA:IgnoreCharacterInventory(deleteChar, true) end,
				}, -- button end
				
				{	type 	= "description", 
					title 	= "Unignore characters",
					text 	= "Adds an ignored character back to the tracking lists",
				},
				{
					type = "dropdown",
					name = "Character to unignore",
					choices = IIfA:GetIgnoredCharacterList(),
					getFunc = function() return end,
					setFunc = function(choice) undeleteChar = nil; undeleteChar = choice end
				}, --dropdown end
				
				{  -- button begin
					type = "button",
					width = "half",
					name = "Unignore",
					tooltip = "All items equipped by the current character will be tracked again",
					func = function() 
						IIfA:IgnoreCharacterEquip(undeleteChar, false) 
						IIfA:IgnoreCharacterInventory(undeleteChar, false)
					end,
				}, -- button end							
				
				{	type 	= "description", 
					title 	= "Guild Bank To Delete",
					text 	= "Delete Inventory Insight data for guild. \nWarning: This change will be applied immediately.",
				},
				{ -- dropdown begin
					 type = "dropdown",
					 name = 'Guild Bank To Delete',
					 choices = getGuildBanks(),
					 getFunc = function() return end,
					 setFunc = function(choice) deleteGBank = nil; deleteGBank = choice end

				}, -- dropdown end

				{	-- button begin
					type = "button",
					name = "Delete Guild Bank",
					tooltip = "Delete Inventory Insight data for the guild selected above",
					func = function() IIfA:DeleteGuildData(deleteGBank) end,
				}, -- button end


			}, -- Collected Guild Bank Data controls end

		}, -- Collected Guild Bank Data submenu end

		{
			type = "submenu",
			name = "Guild Bank Options",
			tooltip = "Manage data collection options for Guild Banks",
			controls = {}
		},
	
		{
			type = "submenu", 
			name = "Houses", 
			controls = {
				
				{
					type = "checkbox",
					name = "Collect furniture in houses",
					tooltip = "Enables/Disables collection of furniture inside houses",
					getFunc = function() return 	IIfA:GetCollectingHouseData() end,
					setFunc = function(value)		IIfA:SetCollectingHouseData(value) end,
				}, -- checkbox end
				
				{	type 	= "description", 
					title 	= "Ignore or delete houses",
					text 	= "removes or un-tracks a house. \nWarning: This change will be applied immediately.",
				},
				{
					type 	= "dropdown",
					name 	= "houses to delete or un-track",
					choices = getHouseNames(),
					getFunc = function() return end,
					setFunc = function(choice) deleteHouse = nil; deleteHouse = choice end
				}, --dropdown end
				{  -- button begin
					type = "button",
					width = "half",
					name = "Ignore house",
					tooltip = "All furniture items in the currently selected house will be untracked",
					func = function() IIfA:SetCollectHouseStatus(deleteHouse, false) end,
				}, -- button end
				{
					type 	= "dropdown",
					name 	= "houses to re-track",
					choices = getIgnoredHouseNames(),
					getFunc = function() return end,
					setFunc = function(choice) restoreHouse = nil; restoreHouse = choice end
				}, --dropdown end
				{  -- button begin
					type = "button",
					width = "half",
					name = "Unignore house",
					tooltip = "All furniture items in the currently selected house will be tracked again",
					func = function() IIfA:SetCollectHouseStatus(restoreHouse, true) end,
				}, -- button end	
			},
		},
		
		{
			type = "submenu",
			name = "Pack Use/Size highlites",
			tooltip = "Set the counts/colors for 2 the levels of count warnings",	--(optional)
			controls = {
				{
				type = "slider",
				name = "Used Space Warning Threshold",
				getFunc = function() return IIfA.data.BagSpaceWarn.threshold end,
				setFunc = function(choice) IIfA.data.BagSpaceWarn.threshold = choice end,
				min = 1,
				max = 100,
				step = 1, --(optional)
				clampInput = true, -- boolean, if set to false the input won't clamp to min and max and allow any number instead (optional)
				decimals = 0, -- when specified the input value is rounded to the specified number of decimals (optional)
				tooltip = "Percent Value: if bag space used is above threshold, it will be shown in the below color",
				default = 85, -- default value or function that returns the default value (optional)
				}, -- slider end

				{
				type = "colorpicker",
				name = "Used Space Warning Color",
				getFunc = function() return IIfA.data.BagSpaceWarn.r, IIfA.data.BagSpaceWarn.g, IIfA.data.BagSpaceWarn.b end,
				setFunc = function(r,g,b,a) IIfA.data.BagSpaceWarn.r = r
						IIfA.data.BagSpaceWarn.g = g
						IIfA.data.BagSpaceWarn.b = b
						IIfA.CharBagFrame.ColorWarn = IIfA.CharBagFrame:rgb2hex(IIfA.data.BagSpaceWarn)
						IIfA.CharBagFrame:RepaintSpaceUsed()
				end, --(alpha is optional)
				tooltip = "Color used to show bag space when greater than the designated threshold",
				default = {r = 230 / 255, g = 130 / 255, b = 0},
				}, -- colorpicker end

				{
				type = "slider",
				name = "Used Space Alert Threshold",
				getFunc = function() return IIfA.data.BagSpaceAlert.threshold end,
				setFunc = function(choice) IIfA.data.BagSpaceAlert.threshold = choice end,
				min = 1,
				max = 100,
				step = 1, --(optional)
				clampInput = true, -- boolean, if set to false the input won't clamp to min and max and allow any number instead (optional)
				decimals = 0, -- when specified the input value is rounded to the specified number of decimals (optional)
				tooltip = "Percent Value: if bag space used is above threshold, it will be shown in the below color",
				default = 95, -- default value or function that returns the default value (optional)
				}, -- slider end

				{
				type = "colorpicker",
				name = "Used Space Alert Color",
				getFunc = function() return IIfA.data.BagSpaceAlert.r, IIfA.data.BagSpaceAlert.g, IIfA.data.BagSpaceAlert.b end,
				setFunc = function(r,g,b,a) IIfA.data.BagSpaceAlert.r = r
						IIfA.data.BagSpaceAlert.g = g
						IIfA.data.BagSpaceAlert.b = b
						IIfA.CharBagFrame.ColorAlert = IIfA.CharBagFrame:rgb2hex(IIfA.data.BagSpaceAlert)
						IIfA.CharBagFrame:RepaintSpaceUsed()
				end, --(alpha is optional)
				tooltip = "Color used to show bag space when greater than the designated threshold",
				default = {r = 1, g = 1, b = 0},
				}, -- colorpicker end

				{
				type = "colorpicker",
				name = "Used Space Full Color",
				getFunc = function() return IIfA.data.BagSpaceFull.r, IIfA.data.BagSpaceFull.g, IIfA.data.BagSpaceFull.b end,
				setFunc = function(r,g,b,a) IIfA.data.BagSpaceFull.r = r
						IIfA.data.BagSpaceFull.g = g
						IIfA.data.BagSpaceFull.b = b
						IIfA.CharBagFrame.ColorFull = IIfA.CharBagFrame:rgb2hex(IIfA.data.BagSpaceFull)
						IIfA.CharBagFrame:RepaintSpaceUsed()
				end, --(alpha is optional)
				tooltip = "Color used to show bag space when it's full",
--				width = "full", --or "half" (optional)
				default = {r = 255, g = 0, b = 0},
				}, -- colorpicker end

			},
		},

		{
			type = "header",
			name = "Global/Per Char settings",
		},
		
			
		

		{
			type = "submenu",
			name = "Tooltips",
			tooltip = "Manage tooltip options for both default and custom IIfA tooltips",
			controls = {
				{
					type = "dropdown",
					name = "Show IIfA Tooltips",
					choices = {"Always", "IIfA", "Never" },
					tooltip = "Choose when to display IIfA info on Tooltips",
					getFunc = function() return IIfA:GetSettings().showToolTipWhen end,
					setFunc = function(value) 	IIfA:GetSettings().showToolTipWhen = value end,
				}, -- checkbox end

				{
					type = "checkbox",
					name = "Show Info in Separate Frame",
					tooltip = "Enables/Disables display of Style Info and Location info in a separate frame, or within the tooltip",
					getFunc = function() return 	IIfA:GetSettings().bInSeparateFrame end,
					setFunc = function(value)		IIfA:GetSettings().bInSeparateFrame = value end,
				}, -- checkbox end

				{
					type = "checkbox",
					name = "Show Style Info",
					tooltip = "Enables/Disables display of Style Info on the tooltips",
					getFunc = function() return IIfA:GetSettings().showStyleInfo end,
					setFunc = function(value) 	IIfA:GetSettings().showStyleInfo = value end,
				}, -- checkbox end

				 {
					type = "colorpicker",
					name = 'Tooltip Inventory Information Text Color',
					tooltip = 'Sets the color of the text for the inventory information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandler:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandler:SetRGBA(...)
						IIfA:GetSettings().in2TextColors = IIfA.colorHandler:ToHex()
					end
				},

				{
					type = "dropdown",
					name = "Tooltips Font",
					tooltip = "The font used for location information added to both default and custom IN2 tooltips",
					choices = LMP:List('font'),
					getFunc = function() return (IIfA:GetSettings().in2TooltipsFont or "ZoFontGame") end,
					setFunc = function( choice )
						IIfA:StatusAlert("[IIfA]:TooltipsFontChanged["..choice.."]")
						IIfA:SetTooltipFont(choice)
					end
				},

				{
					type = "slider",
					name = "Tooltip Font Size",
					tooltip = "The font size used for location information added to both default and custom IIfA tooltips",
					min = 5,
					max = 40,
					step = 1,
					getFunc = function() return IIfA:GetSettings().in2TooltipsFontSize end,
					setFunc = function(value)
						IIfA:GetSettings().in2TooltipsFontSize = value
					end,
				},

			}, -- controls end

		}, -- tooltipOptionsSubWindow end

		{
			type = "checkbox",
			tooltip = "Show Item Count on Right side of list",
			name = "Item Count on Right",
			getFunc = function() return IIfA:GetSettings().showItemCountOnRight end,
			setFunc = function(value)
					IIfA:StatusAlert("[IIfA]:ItemCountOnRight[" .. tostring(value) .. "]")
					IIfA:GetSettings().showItemCountOnRight = value
					IIfA:SetItemCountPosition()
			end,
		},

		{
			type = "dropdown",
			name =  "Default Inventory Frame View",
			tooltip =  "The default view (in the dropdown) set when the inventory frame loads",
			choices = IIfA.dropdownBankNames,
			default = IIfA:GetSettings().in2DefaultInventoryFrameView,
			getFunc = function() return IIfA:GetSettings().in2DefaultInventoryFrameView end,
			setFunc = function( value )
				IIfA:StatusAlert("[IIfA]:DefaultInventoryFrameView["..value.."]")
				IIfA:GetSettings().in2DefaultInventoryFrameView = value
				-- 2015-3-9 Assembler Maniac - next line changed to stop crash
				ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown):SetSelectedItem(value)
				IIfA:SetInventoryListFilter(value)
				return
			end
			-- warning = "Will need to reload the UI",	--(optional)
		},

		{
			type = "checkbox",
			name = "Search Set Names when using Text Filter",
			tooltip = "Enables/Disables set name inclusion in searches",
			getFunc = function() return IIfA:GetSettings().bFilterOnSetNameToo end,
			setFunc = function(value)
				IIfA:GetSettings().bFilterOnSetNameToo = value
			end,
		}, -- checkbox end

		{
			type = "checkbox",
			name = "Default to search only Set Names when using Text Filter",
			tooltip = "Enables/Disables set name inclusion in searches",
			getFunc = function() return IIfA:GetSettings().bFilterOnSetName end,
			setFunc = function(value)
				IIfA:GetSettings().bFilterOnSetName = value
				IIfA.bFilterOnSetName = value
				-- IIFA_GUI_SetNameOnly_Checked:SetHidden(not value)
			end,
		}, -- checkbox end

		{
			type = "header",
			name = "Major Scene Toggles",
		},

		{
			type = "checkbox",
			name = "Inventory scene",
			tooltip = "Makes the Inventory Frame visible while viewing your inventory",
			getFunc = function() return IIfA:GetSceneVisible("inventory") end,
			setFunc = function(value) IIfA:SetSceneVisible("inventory", value) end,

			},

		{
			type = "checkbox",
			tooltip = "Makes the Inventory Frame visible while viewing your bank",
			name = "Bank scene",
			getFunc = function() return IIfA:GetSceneVisible("bank") end,
			setFunc = function(value) IIfA:SetSceneVisible("bank", value) end,
		},

		{
			type = "checkbox",
			name = "Guild Bank scene",
			tooltip = "Makes the Inventory Frame visible while viewing your guild vault",
			getFunc = function() return IIfA:GetSceneVisible("guildBank") end,
			setFunc = function(value) IIfA:SetSceneVisible("guildBank", value) end,
		},

		{
			type = "checkbox",
			name = "Guild Store scene",
			tooltip = "Makes the Inventory Frame visible while accessing the guild store",
			getFunc = function() return IIfA:GetSceneVisible("tradinghouse") end,
			setFunc = function(value) IIfA:SetSceneVisible("tradinghouse", value) end,
		},

		 {
			type = "checkbox",
			name = "Crafting scene",
			tooltip = "Makes the Inventory Frame visible while Crafting",
			getFunc = function() return IIfA:GetSceneVisible("smithing") end,
			setFunc = function(value) IIfA:SetSceneVisible("smithing", value) end,
		},

		 {
			type = "checkbox",
			name = "Vendor scene",
			tooltip = "Makes the Inventory Frame visible while buying/selling",
			getFunc = function() return IIfA:GetSceneVisible("store") end,
			setFunc = function(value)	IIfA:SetSceneVisible("store", value) end,
		},

		 {
			type = "checkbox",
			name = "Stables scene",
			tooltip = "Makes the Inventory Frame visible while talking with the Stablemaster",
			getFunc = function() return IIfA:GetSceneVisible("stables") end,
			setFunc = function(value) IIfA:SetSceneVisible("stables", value) end,
		},


		 {
			type = "checkbox",
			name = "Trading scene",
			tooltip = "Makes the Inventory Frame visible while trading",
			getFunc = function() return IIfA:GetSceneVisible("trade") end,
			setFunc = function(value) IIfA:SetSceneVisible("trade", value) end,
		},

	-- options data end
	}

	-- run through list of options, find one with empty controls, add in the submenu for guild banks options
	local i, data
	for i, data in ipairs(optionsData) do
		if data.controls ~= nil then
			if #data.controls == 0 then
				data.controls[1] =
					{
						type = "checkbox",
						name = "Guild Bank Data Collection",
						tooltip = "Enables/Disables data collection for all guild banks on this account",
						warning = "Guild bank information will not be updated if this option is turned off!",
						getFunc = function() return IIfA.data.bCollectGuildBankData end,
						setFunc = function(value) 
							IIfA.data.bCollectGuildBankData = value
							IIfA.trackedBags[BAG_GUILDBANK] = value
						end,
					}
				for i = 1, GetNumGuilds() do
					local id = GetGuildId(i)
					local guildName = GetGuildName(id)
					data.controls[i + 1] =
					{
						type = "checkbox",
						name = "Collect data for " .. guildName .. "?",
						tooltip = "Enables/Disables data collection for this guild bank",
						warning = "Guild bank information for this guild bank will not be updated if this option is turned off!",
						getFunc = function() return getGuildBankKeepDataSetting(i) end,
						setFunc = function(value) setGuildBankKeepDataSetting(i, value) end,
						disabled = function() return (not IIfA.data.bCollectGuildBankData) end,
					}
	--[[
					{
						type = "checkbox",
						name = "Old Guild Bank Data Alert",
						tooltip = "Enables/Disables an alert that will notify you once, when you first log in, if one or more guild banks contain data that is 5 days or older",
						-- 3-29-15 - AssemblerManiac - changed .data. to :GetSettings(). next 2 occurances
						getFunc = function() return IIfA:GetSettings().in2AgedGuildBankDataWarning end,
						setFunc = function(value)
							IIfA:GetSettings().in2AgedGuildBankDataWarning = value
							end,
					}, -- checkbox end
	]]--
				end
			end
		end
	end

	LAM:RegisterOptionControls("IIfA_OptionsPanel", optionsData)

end

function IIfA:CreateSettingsWindow(savedVars, defaults)

	local panelData = {
		type = "panel",
		name = IIfA.name,
		displayName = name,
		author = IIfA.author,
		version = IIfA.version,
		slashCommand = "/iifa",	--(optional) will register a keybind to open to this panel
		registerForRefresh = true,	--boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
		registerForDefaults = true	--boolean (optional) (will set all options controls back to default values)
	}

	LAM:RegisterAddonPanel("IIfA_OptionsPanel", panelData)

	self:CreateOptionsMenu()

   end
