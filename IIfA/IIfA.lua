------------------------------------------------------------------
--IIfA.lua
--Original Author: Vicster0
--v0.8
-- v1.x and 2.x - rewrites by ManaVortex & AssemblerManiac
-- v3.x - new features mainly by ManaVortex
--[[
	Collects inventory data for all characters on a single account
	including the shared bank and makes this information available
	on tooltips across the entire account providing the player
	with useful insight into their account wide inventory.
DISCLAIMER
	This Add-on is not created by, affiliated with or sponsored by
	ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and
	related logos are registered trademarks or trademarks of
	ZeniMax Media Inc. in the United States and/or other countries.
	All rights reserved."
]]
------------------------------------------------------------------
if IIfA == nil then IIfA = {} end
--local IIfA = IIfA

IIfA.name 				= "Inventory Insight"
IIfA.version 			= "3.06"
IIfA.author 			= "AssemblerManiac & manavortex"
IIfA.defaultAlertSound 	= nil
IIfA.colorHandler 		= nil
IIfA.isGuildBankReady 	= false
IIfA.TooltipLink 		= nil
IIfA.CurrSceneName 		= "hud"
IIfA.bFilterOnSetName 	= false
IIfA.searchFilter 		= ""
IIfA.trackedHouses		= {}

local LMP = LibStub("LibMediaProvider-1.0")
local BACKPACK = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack

local ITEMTOOLTIP = ZO_ItemToolTip
local POPUPTOOLTIP = ZO_PopupToolTip

local IIFA_COLORDEF_DEFAULT = ZO_ColorDef:New("3399FF")

local task 			= IIfA.task or LibStub("LibAsync"):Create("IIfA_DataCollection")
IIfA.task			= task

-- --------------------------------------------------------------
--	Global Variables and external functions
-- --------------------------------------------------------------

-- BAG_SUBSCRIBER_BANK handled special in the CollectAll function - do NOT add to this list

IIfA.trackedBags = {
	[BAG_WORN] 				= true,
	[BAG_BACKPACK] 			= true,
	[BAG_BANK] 				= true,
	[BAG_GUILDBANK] 		= true,
	[BAG_VIRTUAL] 			= true,
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

IIfA.dropdownBankNames = {
	"All",
	"All Banks",
	"All Guild Banks",
	"All Characters",
	"Bank and Characters",
	"Bank and Current Character",
	"Bank and other characters",
	"Bank Only",
	"Craft Bag",
	"Housing Storage",
	"All Houses",
}

function IIfA:GetItemID(itemLink)
	local ret = nil
	if (itemLink) then
		local data = itemLink:match("|H.:item:(.-)|h.-|h")
		local itemID = zo_strsplit(':', data)		-- just get the number

		-- because other functions may be comparing string to string, we can't make this be a number or it won't compare properly
		ret = itemID
	end
	return ret
end

-- 7-26-16 AM - global func, not part of IIfA class, used in IIfA_OnLoad
function IIfA_SlashCommands(cmd)

	if (cmd == "") then
    	d("[IIfA]:Please find the majority of options in the addon settings section of the menu under Inventory Insight.")
    	d(" ")
    	d("[IIfA]:Usage - ")
    	d("	/IIfA [options]")
    	d(" 	")
    	d("	Options")
    	d("		debug - Enables debug functionality for the IIfA addon.")
    	d("		run - Runs the IIfA data collector.")
		d("		color - Opens the color picker dialog to set tooltip text color.")
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
		IIfA:CollectAll()
		return
	end

	if (cmd == "color") then
		local in2ColorPickerOnMouseUp = _in2OptionsColorPicker:GetHandler("OnMouseUp")
		in2ColorPickerOnMouseUp(_in2OptionsColorPicker, nil, true)
		return
	end
end

function IIfA:DebugOut(output, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
	if not IIfA.data.bDebug then return end
	if a10 then
		d(zo_strformat(output, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10))
	elseif a9 then
		d(zo_strformat(output, a1, a2, a3, a4, a5, a6, a7, a8, a9))
	elseif a8 then
		d(zo_strformat(output, a1, a2, a3, a4, a5, a6, a7, a8))
	elseif a7 then
		d(zo_strformat(output, a1, a2, a3, a4, a5, a6, a7))
	elseif a6 then
		d(zo_strformat(output, a1, a2, a3, a4, a5, a6))
	elseif a5 then
		d(zo_strformat(output, a1, a2, a3, a4, a5))
	elseif a4 then
		d(zo_strformat(output, a1, a2, a3, a4))
	elseif a3 then
		d(zo_strformat(output, a1, a2, a3))
	elseif a2 then
		d(zo_strformat(output, a1, a2))
	elseif a1 then
		d(zo_strformat(output, a1))
	elseif output then
		d(zo_strformat(output))
	else
		d("\n")
	end
end

function IIfA:StatusAlert(message)
	if (IIfA.data.bDebug) then
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, IIfA.defaultAlertSound, message)
	end
end

function IIfA:BuildHouseLists()

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

	-- initializing default values
	local defaultGlobal = {
		saveSettingsGlobally 	= true,
		bDebug 					= false,
		in2TextColors 			= IIFA_COLORDEF_DEFAULT:ToHex(),
		showItemCountOnRight 	= true,
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
	}

	-- initializing default values
	local default = {
		in2TextColors = IIFA_COLORDEF_DEFAULT:ToHex(),
		showItemCountOnRight = true,

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
	}

	IIfA.minWidth = 410
	-- prevent resizing by user to be larger than this
	IIFA_GUI:SetDimensionConstraints(IIfA.minWidth, 300, -1, 1400)

	-- Grab a couple static values that shouldn't change while it's running
	IIfA.HeaderHeight = IIFA_GUI_Header:GetHeight()
	IIfA.SearchHeight = IIFA_GUI_Search:GetHeight()

	IIFA_GUI_ListHolder.rowHeight = 52	-- trying to find optimal size for this, set it in one spot for easier adjusting

	IIfA.currentCharacterId = GetCurrentCharacterId()
	IIfA.currentAccount = GetDisplayName()

	IIfA.filterGroup = "All"
	IIfA.filterTypes = nil

	-- grabs data from bagpack, and worn bag when we first open the inventory
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
	local function nukePositioning()
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
	end
	nukePositioning()

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
    local lang = GetCVar("language.2")
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

	if IIfA.data.guildBanks == nil then
		IIfA.data.guildBanks = {}
		local i
		for i = 1, GetNumGuilds() do
			local id = GetGuildId(i)
			local guildName = GetGuildName(id)
			IIfA.data.guildBanks[guildName] = {bCollectData = true, lastCollected = GetDate() .. "@" .. GetFormattedTime(), items = 0}
		end
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
	-- IIFA_GUI_SetNameOnly_Checked:SetHidden(not IIfA.bFilterOnSetName)

	IIFA_GUI_Header_Filter_Button0:SetState(BSTATE_PRESSED)
	IIfA.LastFilterControl = IIFA_GUI_Header_Filter_Button0

	-- save off anchors for the ListHolder
	local _, point, relTo, relPoint, offsX, offsY = IIFA_GUI_ListHolder:GetAnchor(0)
	IIFA_GUI_ListHolder.savedAnchor1 = {point, relTo, relPoint, offsX, offsY}

	_, point, relTo, relPoint, offsX, offsY = IIFA_GUI_ListHolder:GetAnchor(1)
	IIFA_GUI_ListHolder.savedAnchor2 = {point, relTo, relPoint, offsX, offsY}

	IIfA.colorHandler = ZO_ColorDef:New(ObjSettings.in2TextColors)
	SLASH_COMMANDS["/ii"] = IIfA_SlashCommands
	IIfA:CreateSettingsWindow(IIfA.settings, default)

	IIfA.CharCurrencyFrame:Initialize(IIfA.data)
	IIfA.CharBagFrame:Initialize(IIfA.data)

	IIfA:SetupBackpack()	-- setup the inventory frame
	IIfA:CreateTooltips()	-- setup the tooltip frames

	if (IIfA.data.bConvertedGlyphs == nil or IIfA.data.bConvertedLocType == nil) and IIfA.data.DBv3 == nil then
		-- glyphs are currently stored by itemid, remove them so it can store them properly by item link
		for itemLink, DBItem in pairs(IIfA.data.DBv2) do
			if IIfA.data.bConvertedGlyphs == nil then
				if DBItem.attributes.itemName:lower():find("glyph") ~= nil and itemLink:find("|") == nil then
					IIfA.data.DBv2[itemLink] = nil
				end
			end
			for locationName, locData in pairs(DBItem) do
				if locData.locationType ~= nil then
					locData.bagID = locData.locationType
					locData.locationType = nil
				end
			end
		end
		IIfA.data.bConvertedGlyphs = true
		IIfA.data.bConvertedLocType = true
	end
	if IIfA.data.bConvertedMotifs == nil and IIfA.data.DBv2 ~= nil then			-- 9-12-16 AM - added whole if to convert motifs to item ids
		for itemLink, DBItem in pairs(IIfA.data.DBv2) do
			if itemLink:find("|") ~= nil then			-- not a numeric itemid, it's a link
				local itemType = GetItemLinkItemType(itemLink)
				if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then		-- 9-12-16 AM - added because motifs now appear to have level info in them
					itemKey = IIfA:GetItemID(itemLink)
					if IIfA.data.DBv2[itemKey] == nil then
						IIfA.data.DBv2[itemKey] = DBItem
						IIfA.data.DBv2[itemLink] = nil
						IIfA.data.DBv2[itemKey].itemLink = itemLink
					else
						for attrib, data in pairs(DBItem) do
							if data.itemCount ~= nil then
								if IIfA.data.DBv2[itemKey][attrib].itemCount ~= nil then
									IIfA.data.DBv2[itemKey][attrib].itemCount = IIfA.data.DBv2[itemKey][attrib].itemCount + data.itemCount
								else
									IIfA.data.DBv2[itemKey][attrib] = data
								end
							end
						end
						IIfA.data.DBv2[itemKey].attributes.itemLink = itemLink
						IIfA.data.DBv2[itemLink] = nil
					end
				end
			end
		end
		IIfA.data.bConvertedMotifs = true
	end

	if IIfA.data.DBv2 ~= nil then
		dbv3 = {}
		for itemLink, DBItem in pairs(IIfA.data.DBv2) do
			dbv3[itemLink] = {}
			dbv3[itemLink].locations = {}
			dbv3[itemLink].itemQuality = DBItem.attributes.itemQuality
			dbv3[itemLink].itemName    = DBItem.attributes.itemName
			dbv3[itemLink].filterType  = DBItem.attributes.filterType
			if DBItem.attributes.itemLink ~= nil then
				dbv3[itemLink].itemLink = DBItem.attributes.itemLink
			end

			for locname, locdata in pairs(DBItem) do
				if locname ~= "attributes" then
					dbv3[itemLink].locations[locname] = locdata
				end
			end
		end
		IIfA.data.DBv3 = dbv3
		IIfA.data.DBv2 = nil
	end

	-- keep EU and US items apart
	local worldName = GetWorldName():gsub(" Megaserver", "")
	IIfA.data[worldName] = IIfA.data[worldName] or {}
	if IIfA.data[worldName].DBv3 == nil then
		 IIfA.data[worldName].DBv3 = IIfA.data.DBv3
	end
	IIfA.data.DBv3 = nil
	IIfA.database = IIfA.data[worldName].DBv3

	IIfA:ActionLayerInventoryUpdate()

	if not ObjSettings.frameSettings.hud.hidden then
		IIfA:ProcessSceneChange("hud", "showing", "shown")
	end

	IIfA:RegisterForEvents()
	IIfA:RegisterForSceneChanges() -- register for callbacks on scene statechanges using user preferences or defaults

	IIfA.ignoredCharEquipment = IIfA.ignoredCharEquipment or {}
	IIfA.ignoredCharInventories = IIfA.ignoredCharInventories or {}

	IIfA.trackedBags[BAG_WORN] 		= not IIfA:IsCharacterEquipIgnored()
	IIfA.trackedBags[BAG_BACKPACK] 	= not IIfA:IsCharacterInventoryIgnored()

	IIfA:CollectAll()


end

EVENT_MANAGER:RegisterForEvent("IIfALoaded", EVENT_ADD_ON_LOADED, IIfA_onLoad)

function IIfA:ScanCurrentCharacterAndBank()

	IIfA:ScanBank()
	IIfA:ScanCurrentCharacter()
	zo_callLater(function()
		IIfA:MakeBSI()
	end, 5000)
end

function IIfA:MakeBSI()
	local bs = {}
	local idx
	local itemLink, DBItem, locname, data
	for itemLink, DBItem in pairs(IIfA.database) do
		if DBItem.locations then
			for locname, data in pairs(DBItem.locations) do
				if ((data.bagID == BAG_BACKPACK or data.bagID == BAG_WORN) and locname == IIfA.currentCharacterId) or	-- only index items ON this character if they're in backpack
					(data.bagID ~= BAG_BACKPACK and data.bagID ~= BAG_WORN) then
					idx = data.bagID
					if idx == BAG_GUILDBANK then		-- replace idx with appropriate guild bank name instead of the ID for BAG_GUILDBANK (to differentiate guild banks)
						idx = locname
					end
					if bs[idx] == nil then
						bs[idx] = {}
					end
					if nil ~= idx and nil ~= data.bagSlot then
						bs[idx][data.bagSlot] = itemLink
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
