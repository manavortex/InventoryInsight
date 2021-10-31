----------------------------------------------------------------------
--IIfA.lua
--v0.8 - Original Author: Vicster0
-- v1.x and 2.x - rewrites by ManaVortex & AssemblerManiac
-- v3.x - new features mainly by ManaVortex
--[[
	Collects inventory data for all characters on a single account including the shared bank and makes this information available
	on tooltips across the entire account providing the playerwith useful insight into their account wide inventory.
DISCLAIMER
	This Add-on is not created by, affiliated with or sponsored by ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related
	logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. All rights reserved."
]]
-- text searches in non-EN languages improved by Baertram 2019-10-13
----------------------------------------------------------------------
if IIfA == nil then IIfA = {} end

IIfA.name 				= "Inventory Insight"
IIfA.version 			= "3.47"
IIfA.author 			= "AssemblerManiac & manavortex"
IIfA.defaultAlertSound 	= nil
IIfA.colorHandler 		= nil
IIfA.isGuildBankReady 	= false
IIfA.TooltipLink 		= nil
IIfA.CurrSceneName 		= "hud"
IIfA.bFilterOnSetName 	= false
IIfA.searchFilter 		= ""
IIfA.trackedHouses		= {}
IIfA.EMPTY_STRING		= ""
IIfA.BagSlotInfo		= {}		-- 8-4-18 AM - make sure the table exists in case something tries to reference it before it's created.

local BACKPACK = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack

local ITEMTOOLTIP = ZO_ItemToolTip
local POPUPTOOLTIP = ZO_PopupToolTip

local IIFA_COLOR_DEFAULT = ZO_ColorDef:New("3399FF")

local task 			= IIfA.task or LibAsync:Create("IIfA_DataCollection")
IIfA.task			= task

-- --------------------------------------------------------------
--	Global Variables and external functions
-- --------------------------------------------------------------

IIfA.trackedBags = {
	[BAG_WORN] 				= true,
	[BAG_BACKPACK] 			= true,
	[BAG_BANK] 				= true,
	[BAG_SUBSCRIBER_BANK]	= true,
	[BAG_GUILDBANK] 		= true,
	[BAG_VIRTUAL] 			= true,
	[BAG_HOUSE_BANK_ONE] 	= true,
	[BAG_HOUSE_BANK_TWO] 	= true,
	[BAG_HOUSE_BANK_THREE]	= true,
	[BAG_HOUSE_BANK_FOUR] 	= true,
	[BAG_HOUSE_BANK_FIVE] 	= true,
	[BAG_HOUSE_BANK_SIX] 	= true,
	[BAG_HOUSE_BANK_SEVEN] 	= true,
	[BAG_HOUSE_BANK_EIGHT] 	= true,
	[BAG_HOUSE_BANK_NINE] 	= true,
	[BAG_HOUSE_BANK_TEN] 	= true,
	}

IIfA.dropdownLocNames = {
	"All",
	"All Banks",
	"All Guild Banks",
	"All Characters",
	"All Storage",
	"Everything I own",
	"Bank Only",
	"Bank and Characters",
	"Bank and Current Character",
	"Bank and other characters",
	"Craft Bag",
	"Housing Storage",
	"All Houses",
	}

IIfA.dropdownLocNamesTT = {
	["All Storage"] = "Bank, Characters, CraftBag, and Storage Chests/Coffers",
	["Everything I own"] = "Bank, Characters, CraftBag, Storage Chests/Coffers, and Houses",
	["Housing Storage"] = "Storage Chests/Coffers",
	}

-- create some

local strings = {
	IIFA_BAG_BAGPACK 	= "Inventory",
	IIFA_BAG_BANK 		= "Bank",
	IIFA_BAG_CRAFTBAG 	= "CraftBag",
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end


-- 7-26-16 AM - global func, not part of IIfA class, used in IIfA_OnLoad
local function IIfA_SlashCommands(cmd)

	if (cmd == IIfA.EMPTY_STRING) then
		d("[IIfA]:Please find the majority of options in the addon settings section of the menu under Inventory Insight.")
		d(" ")
		d("[IIfA]:Usage - ")
		d("	/IIfA [options]")
		d(" 	")
		d("	Options")
		d("		debug - Enables debug functionality for the IIfA addon.")
		d("		run - Runs the IIfA data collector.")
		d("		color - Opens the color picker dialog to set tooltip text color.")
		d("		toggle - Show/Hide IIfA")
		return
	end

	if (cmd == "debug") then
		if (IIfA.data.bDebug) then
			d("[IIfA]:Debug[Off]")
			IIfA.data.bDebug = false
		else
			d("[IIfA]:Debug[On]")
			IIfA.data.bDebug = true
		end
		return
	end

	if (cmd == "run") then
		d("[IIfA]:Running collector...")
		IIfA:CollectAll(true)
		return
	end

	if (cmd == "color") then
		local in2ColorPickerOnMouseUp = _in2OptionsColorPicker:GetHandler("OnMouseUp")
		in2ColorPickerOnMouseUp(_in2OptionsColorPicker, nil, true)
		return
	end

	if cmd == "toggle" then
		IIfA:ToggleInventoryFrame()
	end
end

function IIfA:DebugOut(output, ...)
	if not IIfA.data.bDebug then return end

	local otype = type(output)

	if output == nil then
		d("\n")
	elseif otype ~= "string" then
		d(output, ...)
	else
		d(zo_strformat(output, ...))
	end
end

function IIfA:StatusAlert(message)
	if (IIfA.data.bDebug) then
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, IIfA.defaultAlertSound, message)
	end
end

function IIfA:TextColorFixup(settings)
--	d("settings.TextColorsCraftBag = " .. settings.TextColorsCraftBag)
	if settings.TextColorsToon == nil then
		if settings.in2TextColors then
--			d("old = " .. settings.in2TextColors)
			self.colorHandlerToon = ZO_ColorDef:New(settings.in2TextColors)
			self.colorHandlerBank = ZO_ColorDef:New(settings.in2TextColors)
			self.colorHandlerGBank = ZO_ColorDef:New(settings.in2TextColors)
			self.colorHandlerHouse = ZO_ColorDef:New(settings.in2TextColors)
			self.colorHandlerHouseChest = ZO_ColorDef:New(settings.in2TextColors)
			self.colorHandlerCraftBag = ZO_ColorDef:New(settings.in2TextColors)
		else
--			d("Using default textcolors")
			self.colorHandlerToon = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
			self.colorHandlerBank = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
			self.colorHandlerGBank = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
			self.colorHandlerHouse = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
			self.colorHandlerHouseChest = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
			self.colorHandlerCraftBag = ZO_ColorDef:New(IIFA_COLOR_DEFAULT:ToHex())
		end
		settings.TextColorsToon = self.colorHandlerToon:ToHex()
		settings.TextColorsBank = self.colorHandlerBank:ToHex()
		settings.TextColorsGBank = self.colorHandlerGBank:ToHex()
		settings.TextColorsHouse = self.colorHandlerHouse:ToHex()
		settings.TextColorsHouseChest = self.colorHandlerHouse:ToHex()
		settings.TextColorsCraftBag = self.colorHandlerCraftBag:ToHex()
		settings.in2TextColors = nil
	else
--		d("using saved textcolors")
		self.colorHandlerToon = ZO_ColorDef:New(settings.TextColorsToon)
		self.colorHandlerBank = ZO_ColorDef:New(settings.TextColorsBank)
		self.colorHandlerGBank = ZO_ColorDef:New(settings.TextColorsGBank)
		self.colorHandlerHouse = ZO_ColorDef:New(settings.TextColorsHouse)
		self.colorHandlerHouseChest = ZO_ColorDef:New(settings.TextColorsHouseChest)
		self.colorHandlerCraftBag = ZO_ColorDef:New(settings.TextColorsCraftBag)
	end
end

--Check if the clientLanguage is using gender specific string suffix like ^mx or ^f which need to be replaced
--by zo_strformat functions
function IIfA:CheckIfClientLanguageUsesGenderStrings(clientLanguage)
	clientLanguage = clientLanguage or GetCVar("language.2")
	if not clientLanguage then return false end
	local clientLanguagesWithGenderSpecificStringsSuffix = {
		["de"] = true,
		["fr"] = true,
	}
	local retVar = clientLanguagesWithGenderSpecificStringsSuffix[clientLanguage] or false
	IIfA.clientLanguageUsesGenderString = retVar
	return retVar
end

function IIfA_onLoad(eventCode, addOnName)
	if (addOnName ~= "IIfA") then
		return
	end

	local valDocked = true
	local valLocked = false
	local valMinimized = false
	local valLastX = 400
	local valLastY = 300
	local valHeight = 798
	local valWidth = 380

	local lang = GetCVar("language.2")
	IIfA.clientLanguage = lang
	IIfA:CheckIfClientLanguageUsesGenderStrings(lang)

	-- initializing default values
	local defaultGlobal = {
		saveSettingsGlobally 	= true,
		bDebug 					= false,
		showItemCountOnRight 	= true,
		showItemStats			= false,
		b_collectHouses			= false,
		collectHouseData		= {},
		ignoredCharEquipment	= {},
		ignoredCharInventories	= {},
		frameSettings =
			{
			["bank"] =			{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["guildBank"] =  	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["tradinghouse"] = 	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["smithing"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["store"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["stables"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["trade"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["inventory"] = 	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["hud"] =   		{ hidden = true,  docked = false,     locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["alchemy"] =   	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth }
			},

		bCollectGuildBankData 			= false,
		in2DefaultInventoryFrameView 	= "All",
		in2AgedGuildBankDataWarning 	= true,
		in2TooltipsFont 				= "ZoFontGame",
		in2TooltipsFontSize 			= 16,
		ShowToolTipWhen 				= "Always",
		DBv3 							= {},
		dontFocusSearch					= false,
		bAddContextMenuEntrySearchInIIfA = true,
	}

	-- initializing default values
	local default = {
		showItemCountOnRight	= true,
		showItemStats			= false,

		frameSettings =
			{
			["bank"] =			{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["guildBank"] =  	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["tradinghouse"] = 	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["smithing"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["store"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["stables"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["trade"] = 		{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["inventory"] = 	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["hud"] =   		{ hidden = true, docked = false, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth },
			["alchemy"] =   	{ hidden = false, docked = valDocked, locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY, height = valHeight, width = valWidth }
			},

		bCollectGuildBankData = false,
		in2DefaultInventoryFrameView = "All",
		in2AgedGuildBankDataWarning = true,
		in2TooltipsFont = "ZoFontGame",
		in2TooltipsFontSize = 16,
		bAddContextMenuEntrySearchInIIfA = true,
	}

	IIfA.minWidth = 410
	-- prevent resizing by user to be larger than this
	IIFA_GUI:SetDimensionConstraints(IIfA.minWidth, 300, -1, 1400)

	-- Grab a couple static values that shouldn't change while it's running
	IIfA.HeaderHeight = IIFA_GUI_Header:GetHeight()
	IIfA.SearchHeight = IIFA_GUI_Search:GetHeight()

	IIFA_GUI_ListHolder.rowHeight = 52	-- trying to find optimal size for this, set it in one spot for easier adjusting
	IIFA_GUI_ListHolder:SetDrawLayer(0)	-- keep the scrollable dropdown ABOVE this one
										-- (otherwise scrollable dropdown is shown like it's above the list, but the mouse events end up going through to the list)

	IIfA.currentCharacterId = GetCurrentCharacterId()
	IIfA.currentAccount = GetDisplayName()

	IIfA.filterGroup = "All"
	IIfA.filterTypes = nil

	-- grabs data from backpack, and worn items when we first open the inventory
	-- ZO_PreHook(PLAYER_INVENTORY, "ApplyBackpackLayout", IIfA.OnFirstInventoryOpen)
	ZO_PreHook(BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT, "ApplyBackpackLayout", IIfA.CollectGuildBank)

	-- ZO_PreHook(SHARED_INVENTORY, "GetOrCreateBagCache", function(self, bagId)
		-- d("SHARED_INVENTORY: GetOrCreateBagCache: " .. tostring(bagId))
	-- end)
	-- ZO_PreHook(SHARED_INVENTORY, "PerformFullUpdateOnBagCache", function(self, bagId)
		-- d("SHARED_INVENTORY: PerformFullUpdateOnBagCache: " .. tostring(bagId))
	-- end)


	-- http://esodata.uesp.net/100016/src/libraries/utility/zo_savedvars.lua.html#67


	IIfA.settings 	= ZO_SavedVars:NewCharacterIdSettings("IIfA_Settings", 1, nil, default)
	IIfA.data 		= ZO_SavedVars:NewAccountWide("IIfA_Data", 1, "Data", defaultGlobal)

	IIfA:RebuildHouseMenuDropdowns()

	--  nuke non-global positioning settings
	local ObjSettings = IIfA:GetSettings()
	if ObjSettings.in2InventoryFrameSceneSettings ~= nil then
		ObjSettings.in2InventoryFrameSceneSettings = nil
	end
	if ObjSettings.in2InventoryFrameScenes ~= nil then
		ObjSettings.in2InventoryFrameScenes = nil
	end
	if ObjSettings.valDocked ~= nil then
		ObjSettings.valDocked = nil
		ObjSettings.valLocked = nil
		ObjSettings.valMinimized = nil
		ObjSettings.valLastX = nil
		ObjSettings.valLastY = nil
		ObjSettings.valHeight = nil
		ObjSettings.valWidth = nil
		ObjSettings.valWideX = nil
	end

	if IIfA.settings.in2ToggleGuildBankDataCollection ~= nil then
		IIfA.settings.in2ToggleGuildBankDataCollection = nil
	end
	if IIfA.data.in2ToggleGuildBankDataCollection ~= nil then
		IIfA.data.bCollectGuildBankData = IIfA.data.in2ToggleGuildBankDataCollection
		IIfA.data.in2ToggleGuildBankDataCollection = nil
	end

	if IIfA.data.showToolTipOnIIFAOnly ~= nil then
		if IIfA.data.showToolTipWhen == nil then		-- safety test - this should be nil at this point, but ya never know
			if IIfA.data.showToolTipOnIIFAOnly then
				IIfA.data.showToolTipWhen = "IIfA"
			else
				IIfA.data.showToolTipWhen = "Always"
			end
		end
		IIfA.data.showToolTipOnIIFAOnly = nil
	else
		if IIfA.data.showToolTipWhen == nil then
			IIfA.data.showToolTipWhen = "Always"
		end
	end
	if ObjSettings.showToolTipOnIIFAOnly ~= nil then
		if ObjSettings.showToolTipWhen == nil then		-- safety test - this should be nil at this point, but ya never know
			if ObjSettings.showToolTipOnIIFAOnly then
				ObjSettings.showToolTipWhen = "IIfA"
			else
				ObjSettings.showToolTipWhen = "Always"
			end
		end
		ObjSettings.showToolTipOnIIFAOnly = nil
	else
		if ObjSettings.showToolTipWhen == nil then
			ObjSettings.showToolTipWhen = IIfA.data.showToolTipWhen
		end
	end

	if IIfA.data.showStyleInfo == nil then
		IIfA.data.showStyleInfo = true
	end
	if ObjSettings.showStyleInfo == nil then
		ObjSettings.showStyleInfo = IIfA.data.showStyleInfo
	end


	-- 2-9-17 AM - convert saved data names into proper language for this session
	if IIfA.data.lastLang == nil or IIfA.data.lastLang ~= lang then
		IIfA:RenameItems()
		IIfA.data.lastLang = lang
	end

	IIfA:SetupCharLookups()

	-- overwrite non-global tables if present

	IIfA.settings.accountCharacters = nil
	IIfA.settings.guildBanks = nil


	-- this MUST remain in this location, otherwise it's possible that CollectAll will remove ALL characters data from the list (because they haven't been converted)
	if IIfA.data.accountCharacters ~= nil then
		IIfA:ConvertNameToId()
		IIfA.data.accountCharacters = nil
	end

	if ObjSettings.bFilterOnSetNameToo == nil then
		ObjSettings.bFilterOnSetNameToo = false
		IIfA.data.bFilterOnSetNameToo = false
	end

	-- Other addons: FCOItemSaver
	if ObjSettings.FCOISshowMarkerIcons == nil then
		ObjSettings.FCOISshowMarkerIcons = false
		IIfA.data.FCOISshowMarkerIcons = false
	end

	-- manavortex, Feb. 22 2018: drop dbv2 support
	if nil ~= IIfA.data.DBv2 then IIfA.data.DBv2 = nil end

	-- store EU and US items separately
	local worldName = GetWorldName():gsub(" Megaserver", IIfA.EMPTY_STRING)
	IIfA.data[worldName] = IIfA.data[worldName] or {}
	if IIfA.data[worldName].DBv3 == nil then
		 IIfA.data[worldName].DBv3 = IIfA.data.DBv3
	end
	IIfA.data.DBv3 = nil
	IIfA.database = IIfA.data[worldName].DBv3

	-- 2018-10-11 AM - guildBanks now tracked individually per server (NA or EU)
	IIfA:SetupGuildBanks(worldName)

	if IIfA.InventoryListFilter == "All Account Owned" then
		IIfA.InventoryListFilter = "All Storage"
	end

	if ObjSettings.bInSeparateFrame == nil then
		ObjSettings.bInSeparateFrame = true
		IIfA.data.bInSeparateFrame = true
	end

	IIfA.bFilterOnSetName = ObjSettings.bFilterOnSetName
	if ObjSettings.bFilterOnSetName == nil then
		IIfA.bFilterOnSetName = false
		ObjSettings.bFilterOnSetName = false
	end

	IIFA_GUI_Header_Filter_Button0:SetState(BSTATE_PRESSED)
	IIfA.LastFilterControl = IIFA_GUI_Header_Filter_Button0

	IIfA.GUI_SearchBox = IIFA_GUI_SearchBackdropBox
	IIfA.GUI_SearchBoxText = IIFA_GUI_SearchBackdropBoxText

	IIfA:TextColorFixup(IIfA:GetSettings())

	SLASH_COMMANDS["/ii"] = IIfA_SlashCommands
	IIfA:CreateSettingsWindow(IIfA.settings, default)

	IIFA_GUI_ListHolder_Counts:SetHidden(not IIfA:GetSettings().showItemStats)

	IIfA.CharCurrencyFrame:Initialize(IIfA.data)
	IIfA.CharBagFrame:Initialize(IIfA.data)

	IIfA:SetupBackpack()	-- setup the inventory frame
	IIfA:CreateTooltips()	-- setup the tooltip frames

	if not ObjSettings.frameSettings.hud.hidden then
		IIfA:ProcessSceneChange("hud", "showing", "shown")
	end

	IIFA_GUI_Header_Hide:SetHidden(ObjSettings.hideCloseButton or false)


	IIfA:RegisterForEvents()
	IIfA:RegisterForSceneChanges() -- register for callbacks on scene statechanges using user preferences or defaults

	IIfA.ignoredCharEquipment = IIfA.ignoredCharEquipment or {}
	IIfA.ignoredCharInventories = IIfA.ignoredCharInventories or {}
	IIfA.trackedBags[BAG_WORN] 		= not IIfA:IsCharacterEquipIgnored()
	IIfA.trackedBags[BAG_BACKPACK] 	= not IIfA:IsCharacterInventoryIgnored()

	IIfA:CollectAll(true)
end

EVENT_MANAGER:RegisterForEvent("IIfALoaded", EVENT_ADD_ON_LOADED, IIfA_onLoad)


function IIfA:SetupGuildBanks(worldName)
	local tblName = worldName .. "-guildBanks"
	if self.data[tblName] == nil then
		self.data[tblName] = {}
	end
	self.guildBanks = IIfA.data[tblName]

	local i, id, guildName
	for i = 1, GetNumGuilds() do
		id = GetGuildId(i)
		guildName = GetGuildName(id)
		if self.guildBanks[guildName] == nil then
			self.guildBanks[guildName] = {bCollectData = false, lastCollected = IIfA.EMPTY_STRING, items = 0}
		end
	end

	local found = false
	if self.data.guildBanks ~= nil then
		for bankName, data in pairs(self.data.guildBanks) do
			if self.guildBanks[bankName] ~= nil then
				self.guildBanks[bankName] = data
				found = true
			end
		end
		-- don't delete guildBanks unless you're on the right server (it'll only have data in it for one of them)
		if found then
			self.data.guildBanks = nil
		end
	end
end

function IIfA:ScanCurrentCharacterAndBank()

	IIfA:ScanBank()
	IIfA:ScanCurrentCharacter()
--	zo_callLater(function()
--		IIfA:MakeBSI()
--	end, 5000)
end

function IIfA:MakeBSI()
	local bs = {}
	local idx
	local itemKey, DBItem, locname, data
	local bagSlot, qty
	for itemKey, DBItem in pairs(IIfA.database) do
		if DBItem.locations then
			for locname, data in pairs(DBItem.locations) do
				if data.bagSlot ~= nil and type(data.bagSlot) ~= "table" then
					bagSlot = data.bagSlot
					data.bagSlot = {}
					data.bagSlot[bagSlot] = data.itemCount
					data.itemCount = nil
				end
				if ((data.bagID == BAG_BACKPACK or data.bagID == BAG_WORN) and locname == IIfA.currentCharacterId) or	-- only index items ON this character if they're in backpack
					(data.bagID ~= BAG_BACKPACK and data.bagID ~= BAG_WORN) then
					idx = data.bagID
					if nil ~= idx then
						if idx == BAG_GUILDBANK then		-- replace idx with appropriate guild bank name instead of the ID for BAG_GUILDBANK (to differentiate guild banks)
							idx = locname
						end
						bs[idx] = bs[idx] or {}
						if nil ~= data.bagSlot then
							for bagSlot, qty in pairs(data.bagSlot) do
								bs[idx][bagSlot] = itemKey
							end
						end
					end
				end
			end
		end
	end
	IIfA.BagSlotInfo = bs
	return bs	-- return only used in IIfA:SaveBagSlotIndex when IIfA.BagSlotInfo is nil
end

--[[
for reference

GetCurrentCharacterId()
Returns: string id

GetNumCharacters()
Returns: integer numCharacters

GetCharacterInfo(luaindex index)
Returns: string name,
		[Gender|#Gender] gender,
		integer level,
		integer classId,
		integer raceId,
		[Alliance|#Alliance] alliance,
		string id,
		integer locationId
__________________
	--]]

function IIfA:SetupCharLookups()

	IIfA.CharIdToName = {}
	IIfA.CharNameToId= {}
	local charInfo = {}
	-- create transient pair of lookup arrays, CharIdToName and CharNameToId (for use with the dropdown and converting stored data char name to charid)
	for i=1, GetNumCharacters() do
		local charName, _, _, _, _, _, charId, _ = GetCharacterInfo(i)
		charName = charName:sub(1, charName:find("%^") - 1)
		IIfA.CharIdToName[charId] = charName
		IIfA.CharNameToId[charName] = charId
	end
end

function IIfA:ConvertNameToId()
	-- run list of dbv2 items, change names to ids
	-- ignore attributes, and anything that's in guild bank list
	-- remaining items are character names (or should be)
	-- if found in CharNameToId, convert it, otherwise erase whole entry (since it's an orphan)
	-- do same for settings
	local tbl = IIfA.data.DBv2
	if nil == tbl or {} == tbl then return end
	for itemLink, DBItem in pairs(IIfA.data.DBv2) do
		for itemDetailName, itemInfo in pairs(DBItem) do
			local bagID = itemInfo.locationType
			if bagID ~= nil then
				if bagID == BAG_BACKPACK or bagID == BAG_WORN then
					if IIfA.CharNameToId[itemDetailName] ~= nil then
	--					d("Swapping name to # -- " .. itemLink .. ", " )
						DBItem[IIfA.CharNameToId[itemDetailName] ] = DBItem[itemDetailName]
						DBItem[itemDetailName] = nil
					end
				end
			end
		end
	end
end


-- used for testing - wipes all craft bag data
function IIfA:clearvbag()
	for itemLink, DBItem in pairs(IIfA.database) do
		for locationName, locData in pairs(DBItem.locations) do
--			if locData.bagID ~= nil then
				if locData.bagID == BAG_VIRTUAL then
					locData = nil
					DBItem[locationName] = nil
				end
--			end
		end
	end
end
