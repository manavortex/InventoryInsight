--this creates a menu for the addon.
--IIfA = IIfA		-- necessary for initial load of the lua script, so it know

local LAM = LibAddonMenu2

local id, guildName, deleteHouse, restoreHouse, name

IIfA.fontFaces = {}
IIfA.fontFaces["ProseAntique"]			= "EsoUI/Common/Fonts/ProseAntiquePSMT.otf"
IIfA.fontFaces["Consolas"]				= "EsoUI/Common/Fonts/consola.ttf"
IIfA.fontFaces["Futura Condensed"]		= "EsoUI/Common/Fonts/FTN57.otf"
IIfA.fontFaces["Futura Condensed Bold"]	= "EsoUI/Common/Fonts/FTN87.otf"
IIfA.fontFaces["Futura Condensed Light"]	= "EsoUI/Common/Fonts/FTN47.otf"
IIfA.fontFaces["Futura STD Condensed"]		= "EsoUI/Common/Fonts/FuturaSTD-Condensed.otf"
IIfA.fontFaces["Futura STD Condensed Bold"]	= "EsoUI/Common/Fonts/FuturaSTD-CondensedBold.otf"
IIfA.fontFaces["Futura STD Condensed Light"]	= "EsoUI/Common/Fonts/FuturaSTD-CondensedLight.otf"
IIfA.fontFaces["Skyrim Handwritten"]		= "EsoUI/Common/Fonts/Handwritten_Bold.otf"
IIfA.fontFaces["Trajan Pro"]				= "EsoUI/Common/Fonts/trajanpro-regular.otf"
IIfA.fontFaces["Univers 55"]				= "EsoUI/Common/Fonts/univers55.otf"
--IIfA.fontFaces["Univers LT Std 55"]	= "EsoUI/Common/Fonts/univers55.otf"
IIfA.fontFaces["Univers 57"]				= "EsoUI/Common/Fonts/univers57.otf"
--IIfA.fontFaces["Univers LT Std 57 Cn"]	= "EsoUI/Common/Fonts/univers57.otf"
IIfA.fontFaces["Univers 67"]				= "EsoUI/Common/Fonts/univers67.otf"
--IIfA.fontFaces["Univers LT Std 57 Cn Lt"]	= "EsoUI/Common/Fonts/univers67.otf"

local effectList = {"none", "outline", "thin-outline", "thick-outline", "shadow", "soft-shadow-thin", "soft-shadow-thick"}
--local effectValues = {"", "outline", "thin-outline", "thick-outline", "shadow", "soft-shadow-thin", "soft-shadow-thick"}

IIfA.fontRef = {}
local faceList = {}
local faceValues = {}

local function buildFontRef()
	local varName, Data

	for varName, Data in pairs(IIfA:GetFontList()) do
		if Data ~= 'Tooltip Default' and Data ~= "Custom" then
			local gData = _G[Data]
			if gData and gData.GetFontInfo then
				local fName, fSize, fEffect = gData:GetFontInfo()
				if fEffect == nil or fEffect == "" then
					fEffect = "none"
				end
				IIfA.fontRef[fName:lower() .. "|" .. fSize .. "|" .. fEffect:lower()] = Data
			end
		end
	end

	local idx
	local data
	for idx, data in pairs(IIfA.fontFaces) do
		faceList[#faceList + 1] = idx
		faceValues[#faceValues + 1] = data:lower()
	end
end


local function getGuildBanks()
	local guildBanks = {}
	local guildName, guildData
	if IIfA.guildBanks then
		for guildName, guildData in pairs(IIfA.guildBanks) do
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

local function getGuildBankKeepDataSetting(guildNum)
	guildName = getGuildBankName(guildNum)

	if IIfA.guildBanks[guildName] == nil then return false end

	if IIfA.guildBanks[guildName].bCollectData == nil then
		IIfA.guildBanks[guildName].bCollectData = true
	end

	return IIfA.guildBanks[guildName].bCollectData
end

local function setGuildBankKeepDataSetting(guildNum, newSetting)
	guildName = getGuildBankName(guildNum)
	if guildName ~= nil then
		IIfA.guildBanks[guildName].bCollectData = newSetting
	end
end

function IIfA:CreateOptionsMenu()
	local deleteChar, deleteGBank

	buildFontRef()

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
			setFunc = function(value) IIfA.data.bDebug = value end,
		},

		{
			type = "submenu",
			name = "Manage Collected Data",
			tooltip = "Manage collected Characters and Guild Banks. Delete data you no longer need (old guilds or deleted characters)",	--(optional)
			controls = {
				{  -- button begin
					type = "button",
					name = "Wipe database",
					tooltip = "Deletes all collected data",
					func = function()
						IIfA.database = {}
						IIfA:ScanCurrentCharacterAndBank()
						IIfA:RefreshInventoryScroll()
					end,
				}, -- button end

				{	type 	= "description",
					title 	= "Ignore or delete characters",
					text 	= "removes or un-tracks a character. \nWarning: This change will be applied immediately.",
				},
				{
					type 	= "dropdown",
					name 	= "characters to delete or un-track",
					choices = IIfA:GetCharacterList(),
					getFunc = function() return end,
					setFunc = function(choice) deleteChar = nil; deleteChar = choice end,
				}, --dropdown end

				{  -- button begin
					type = "button",
					name = "Delete Character",
					tooltip = "Delete Inventory Insight data for the character selected above",
					func = function() IIfA:DeleteCharacterData(deleteChar) end,
				}, -- button end

				{
					type = "divider",
				},

				{
					type = "checkbox",
					name = "Ignore Char Backpack",
					tooltip = "Ignore Backpack Items on this Character",
					getFunc = function() return IIfA:IsCharacterInventoryIgnored() end,
					setFunc = function(...) IIfA:IgnoreCharacterInventory(...) end,
				}, -- checkbox end

				{
					type = "checkbox",
					name = "Ignore Char Equipment",
					tooltip = "Ignore Worn/Equipped Items on this Character",
					getFunc = function() return IIfA:IsCharacterEquipIgnored() end,
					setFunc = function(...) IIfA:IgnoreCharacterEquip(...) end,
				}, -- checkbox end


				{
					type = "divider",
				},



				{	type 	= "description",
					title 	= "Guild Bank To Delete",
					text 	= "Delete Inventory Insight data for guild. \nWarning: This change will be applied immediately.",
				},
				{	-- dropdown begin
					type = "dropdown",
					name = 'Guild Bank To Delete',
					choices = getGuildBanks(),
					getFunc = function() return end,
					setFunc = function(choice) deleteGBank = nil; deleteGBank = choice end,

				},	-- dropdown end

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
					getFunc = function() return 	IIfA.data.b_collectHouses end,
					setFunc = function(value)		IIfA:SetHouseTracking(value) end,
				}, -- checkbox end

				{	type 	= "description",
					title 	= "Ignore or delete houses",
					text 	= "removes or un-tracks a house. \nWarning: This change will be applied immediately.",
				},
				{  	--dropdown houses to delete or un-track
					type 	= "dropdown",
					name 	= "houses to delete or un-track",
					choices = IIfA:GetTrackedHouseNames(),
					getFunc = function() return end,
					setFunc = function(choice) deleteHouse = nil; deleteHouse = choice end,
				}, --dropdown end
				{  -- button begin
					type = "button",
					width = "half",
					name = "Ignore house",
					tooltip = "All furniture items in the currently selected house will be untracked",
					func = function() IIfA:SetTrackingForHouse(deleteHouse, false) end,
				}, -- button end
				{
					type 	= "dropdown",
					name 	= "houses to re-track",
					choices = IIfA:GetIgnoredHouseNames(),
					getFunc = function() return end,
					setFunc = function(choice) restoreHouse = nil; restoreHouse = choice end,
				}, --dropdown end
				{  -- button begin
					type = "button",
					width = "half",
					name = "Unignore house",
					tooltip = "All furniture items in the currently selected house will be tracked again",
					func = function() IIfA:SetTrackingForHouse(restoreHouse, true) end,
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

		{	-- header: Global/Per Char settings
			type = "header",
			name = "Global/Per Char settings",
		},




		{	-- submenu: tooltips
			type = "submenu",
			name = "Tooltips",
			tooltip = "Manage tooltip options for both default and custom IIfA tooltips",
			controls = { -- tooltips
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
					name = 'Tooltip Owner Text Color - Characters',
					tooltip = 'Sets the color of the text for the chacter owner information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerToon:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerToon:SetRGBA(...)
						IIfA:GetSettings().TextColorsToon = IIfA.colorHandlerToon:ToHex()
					end
				},

				{
					type = "colorpicker",
					name = 'Tooltip Owner Text Color - Banks',
					tooltip = 'Sets the color of the text for the bank owner information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerBank:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerBank:SetRGBA(...)
						IIfA:GetSettings().TextColorsBank = IIfA.colorHandlerBank:ToHex()
					end
				},

				{
					type = "colorpicker",
					name = 'Tooltip Owner Text Color - Guild Banks',
					tooltip = 'Sets the color of the text for guild bank owner information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerGBank:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerGBank:SetRGBA(...)
						IIfA:GetSettings().TextColorsGBank = IIfA.colorHandlerGBank:ToHex()
					end
				},

				{
					type = "colorpicker",
					name = 'Tooltip Owner Text Color - House Chests',
					tooltip = 'Sets the color of the text for housing container information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerHouseChest:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerHouseChest:SetRGBA(...)
						IIfA:GetSettings().TextColorsHouseChest = IIfA.colorHandlerHouseChest:ToHex()
					end
				},

				{
					type = "colorpicker",
					name = 'Tooltip Owner Text Color - House Contents',
					tooltip = 'Sets the color of the text for house location information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerHouse:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerHouse:SetRGBA(...)
						IIfA:GetSettings().TextColorsHouse = IIfA.colorHandlerHouse:ToHex()
					end
				},

				{
					type = "colorpicker",
					name = 'Tooltip Owner Text Color - Craft Bag',
					tooltip = 'Sets the color of the text for craft bag location information that gets added to Tooltips.',
					getFunc = function() return IIfA.colorHandlerCraftBag:UnpackRGBA() end,
					setFunc = function(...)
						IIfA.colorHandlerCraftBag:SetRGBA(...)
						IIfA:GetSettings().TextColorsCraftBag = IIfA.colorHandlerCraftBag:ToHex()
					end
				},

				{
					type = "dropdown",
					name = "Tooltip Font",
					tooltip = "The font used for location information added to both default and custom tooltips",
					choices = IIfA:GetFontList(),
					scrollable = true,
					--sort = "name-up",
					getFunc = function() return (IIfA:GetSettings().in2TooltipsFont or "ZoFontGame") end,
					setFunc = function( choice )
						IIfA:StatusAlert("[IIfA]:TooltipsFontChanged["..choice.."]")
						IIfA:SetTooltipFont(choice)
					end
				},
				{
					type = "dropdown",
					name = "Tooltip Font Face",
					tooltip = "The font face used for location information added to tooltips",
					choices = faceList,
					choicesValues = faceValues,
					scrollable = true,
					reference = "IIfA_FontFace",
					sort = "name-up",
					getFunc = function() return (IIfA:GetSettings().TooltipFontFace or "Univers 55") end,
					setFunc = function( choice )
						IIfA:StatusAlert("[IIfA]:TooltipFontFaceChanged["..choice.."]")
						IIfA:SetTooltipFont(nil, choice, nil, nil)
					end
				},
				{
					type = "slider",
					name = "Tooltip Font Size",
					tooltip = "The font size used for location information added to both default and custom tooltips",
					min = 5,
					max = 40,
					step = 1,
					reference = "IIfA_FontSize",
					getFunc = function() return IIfA:GetSettings().TooltipFontSize or 12 end,
					setFunc = function(value)
						IIfA:StatusAlert("[IIfA]:TooltipFontSizeChanged[" .. value .. "]")
							IIfA:SetTooltipFont(nil, nil, value, nil)
						end,
				},
				{
					type = "dropdown",
					name = "Tooltip Font Effect",
					tooltip = "The font effect used for location information added to tooltips",
					choices = effectList,
--					choicesValues = effectValues,
					scrollable = true,
					reference = "IIfA_FontEffect",
					getFunc = function() return (IIfA:GetSettings().TooltipFontEffect or "none") end,
					setFunc = function( choice )
						IIfA:StatusAlert("[IIfA]:TooltipFontEffectChanged["..choice.."]")
						IIfA:SetTooltipFont(nil, nil, nil, choice)
					end
				},

			}, -- controls end

		}, -- tooltipOptionsSubWindow end

		{	-- checkbox: item count on the right
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

		{	-- checkbox: show item count/slot count stats
			type = "checkbox",
			tooltip = "Show Item Stats below list",
			name = "Show Item Stats",
			getFunc = function() return IIfA:GetSettings().showItemStats end,
			setFunc = function(value)
					IIfA:StatusAlert("[IIfA]:ItemStats[" .. tostring(value) .. "]")
					IIfA:GetSettings().showItemStats = value
					IIFA_GUI_ListHolder_Counts:SetHidden(not value)
			end,
		},

		{
			type = "dropdown",
			name =  "Default Inventory Frame View",
			tooltip =  "The default view (in the dropdown) set when the inventory frame loads",
			choices = IIfA.dropdownLocNames,
			default = IIfA:GetSettings().in2DefaultInventoryFrameView,
			scrollable = true,
			getFunc = function() return IIfA:GetSettings().in2DefaultInventoryFrameView end,
			setFunc = function( value )
				IIfA:StatusAlert("[IIfA]:DefaultInventoryFrameView["..value.."]")
				IIfA:GetSettings().in2DefaultInventoryFrameView = value
				ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown_Main):SetSelectedItem(value)
				IIfA:SetInventoryListFilter(value)
				return
			end
			-- warning = "Will need to reload the UI",	--(optional)
		},

		{ -- checkbox: Focus search box on UI toggle
			type = "checkbox",
			name = "Focus search box",
			tooltip = "Focus search bar after UI toggle?",
			getFunc = function() return not IIfA:GetSettings().dontFocusSearch end,
			setFunc = function(value) IIfA:GetSettings().dontFocusSearch = not value end,
		}, -- checkbox end

		{
			type = "checkbox",
			name = "Text Filter considers set name as well",
			tooltip = "Enables/Disables set name inclusion in searches",
			getFunc = function() return IIfA:GetSettings().bFilterOnSetNameToo end,
			setFunc = function(value) IIfA:GetSettings().bFilterOnSetNameToo = value end,
		}, -- checkbox end

		{
			type = "checkbox",
			name = "Text Filter only searches set name",
			tooltip = "Enables/Disables set name inclusion in searches",
			getFunc = function() return IIfA:GetSettings().bFilterOnSetName end,
			setFunc = function(value)
				IIfA:GetSettings().bFilterOnSetName = value
				IIfA.bFilterOnSetName = value
			end,
		}, -- checkbox end

		{
			type = "checkbox",
			name = "Add \'Search in IIfA\' context menu entry",
			tooltip = "Add a context menu entry to items which will open and search in the IIfA frame for this item.\nThis setting needs the library \'LibCustomMenu\' installed and enabled!",
			getFunc = function() return IIfA:GetSettings().bAddContextMenuEntrySearchInIIfA end,
			setFunc = function(value)
				IIfA:GetSettings().bAddContextMenuEntrySearchInIIfA = value
				IIfA.bAddContextMenuEntrySearchInIIfA = value
			end,
			disabled = function() return LibCustomMenu == nil or false end,
			requiresReload 	= true,
		}, -- checkbox end

		{	-- checkbox: show close button
			type = "checkbox",
			tooltip = "Hide Close Button",
			name = "Hide Close Button",
			getFunc = function() return IIfA:GetSettings().hideCloseButton or false end,
			setFunc = function(value)
					IIfA:StatusAlert("[IIfA]:hideCloseButton[" .. tostring(value) .. "]")
					IIfA:GetSettings().hideCloseButton = value
					IIFA_GUI_Header_Hide:SetHidden(value)
			end,
		},

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
			name = "Alchemy scene",
			tooltip = "Makes the Inventory Frame visible while crafting potions/poisons",
			getFunc = function() return IIfA:GetSceneVisible("alchemy") end,
			setFunc = function(value) IIfA:SetSceneVisible("alchemy", value) end,
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

	if FCOIS then
		optionsData[#optionsData + 1] =
			--Other addons
			{
				type = "header",
				name = "Other addons",
			}
		optionsData[#optionsData + 1] =
			--FCOItemSaver
			{
				type = "submenu",
				name = "FCOItemSaver",
				tooltip = "Manage settings for the addon FCOItemSaver within IIfA",
				controls = {
					{
						type = "checkbox",
						name = "Show marker icons",
						tooltip = "Shows FCOIS marker icons within the inventory frame rows",
						getFunc = function() return IIfA:GetSettings().FCOISshowMarkerIcons end,
						setFunc = function(value) IIfA:GetSettings().FCOISshowMarkerIcons = value end,
					},
				},
			}
	end


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

function IIfA:GetFontList()
	local apiVer = GetAPIVersion()
	if self.data.fontList == nil or IIfA.data.fontList[apiVer] == nil then
		self.data.fontList = {}
		self.data.fontList[apiVer] = {}

		local fonts = {}
		local varname, value
		for varname, value in zo_insecurePairs(_G) do
    	    if(type(value) == "userdata" and value.GetFontInfo) then
    	        fonts[#fonts + 1] = varname
    	    end
    	end
		table.sort(fonts)
		local newList = { "Tooltip Default", "Custom" }
		for varname, value in pairs(fonts) do
			newList[#newList + 1] = value
		end
		self.data.fontList[apiVer] = newList
	end

	return self.data.fontList[apiVer]
end


--get LAM DDLB control, then use this to update contents
-- control:UpdateChoices(dropdownData.choices, dropdownData.choicesValues)

