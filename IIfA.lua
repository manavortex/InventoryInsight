------------------------------------------------------------------
--IIfA.lua
--Author: Vicster0
--v0.8
--[[
	Collects inventory data for all characters on a single account
	including the shared bank and makes this information available
	on tooltips across the entire account providing the player
	with useful insight into their account wide inventory.
]]
--[[DISCLAIMER
	This Add-on is not created by, affiliated with or sponsored by
	ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and
	related logos are registered trademarks or trademarks of
	ZeniMax Media Inc. in the United States and/or other countries.
	All rights reserved."
]]
------------------------------------------------------------------
IIfA = {}
local IIfA = IIfA

IIfA.name = "Inventory Insight From Ashes"
IIfA.version = "1.3"
IIfA.author = "manavortex & AssemblerManiac"
IIfA.settings = {}
IIfA.data = {}
IIfA.defaultAlertType = UI_ALERT_CATEGORY_ALERT
IIfA.defaultAlertSound = nil
IIfA.PlayerLoadedFired = false
IIfA.InventoryFrame_SortOrder = 2		-- IN2_SORT_UP
IIfA.CharacterNames = {}
IIfA.colourHandler = nil
IIfA.GuildBankReady = false

--[[--------------------------------------------------------------
--	Local Variables, Libraries, and Definitions
--]]--------------------------------------------------------------
local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMediaProvider-1.0")
--local LAM_vicstersAddons = _vicstersAddons

local BACKPACK = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack

local ITEMTOOLTIP = ZO_ItemToolTip
local POPUPTOOLTIP = ZO_PopupToolTip

local IN2_COLORDEF_RED = ZO_ColorDef:New("FF0000")
local IN2_COLORDEF_GREEN = ZO_ColorDef:New("00FF00")
local IN2_COLORDEF_BLUE = ZO_ColorDef:New("0000FF")
local IN2_COLORDEF_DEFAULT = ZO_ColorDef:New("3399FF")

local LEFTPANEL_ORIGINAL_HEIGHT = ZO_SharedThinLeftPanelBackgroundRight:GetHeight()
local LEFTPANEL_NEW_HEIGHT = 1000

--[[--------------------------------------------------------------
--	Global Variables and external functions
--]]--------------------------------------------------------------

IN2_CURRENT_MOUSEOVER_LINK = nil

POPUPTOOLTIP_ORIGINAL_ADDGAMEDATA_HANDLER = PopupTooltip:GetHandler("OnAddGameData")
POPUPTOOLTIP_ORIGINAL_SHOW_HANDLER = PopupTooltip:GetHandler("OnShow")
POPUPTOOLTIP_ORIGINAL_UPDATE_HANDLER = PopupTooltip:GetHandler("OnUpdate")
POPUPTOOLTIP_ORIGINAL_HIDE_HANDLER = PopupTooltip:GetHandler("OnHide")
ITEMTOOLTIP_ORIGINAL_ADDGAMEDATA_HANDLER = ItemTooltip:GetHandler("OnAddGameData")
ITEMTOOLTIP_ORIGINAL_SHOW_HANDLER = ItemTooltip:GetHandler("OnShow")
ITEMTOOLTIP_ORIGINAL_UPDATE_HANDLER = ItemTooltip:GetHandler("OnUpdate")
ITEMTOOLTIP_ORIGINAL_HIDE_HANDLER = ItemTooltip:GetHandler("OnHide")

--[[--------------------------------------------------------------
--	IIfA Prototypes
--]]--------------------------------------------------------------

in2_item = {
	link = "",
	itemInstanceId = "",
	itemCount = 0,
}

in2_bag ={
	items = {},
}

in2_accountCharacter = {
	characterName = "",
	bag = in2_bag,
}

in2_inventoryTable = {
	bankBag = in2_bag,
	guildBanks = {},
	accountCharacters = {},
}

-- todo: eliminate in2ShowInventoryFrame from the code

function IIfA.IIfA_Loaded(eventCode, addOnName)

	if (addOnName ~= "IIfA") then
		return
	end

	-- initializing default values
	local default = {
		--in2Toggle = true,
		in2ToggleDataCollection = true,
		in2ToggleDefaultTooltips = false,
		in2ToggleIN2Tooltips = true,
		in2Debug = false,
		in2TextColors = IN2_COLORDEF_DEFAULT:ToHex(),
		in2HideRedundantInfo = false,
		in2CompareByName = false,
		in2CompareByLevel = false,
		in2CompareByColor = false,

		--in2InventoryFrame options for enabling and dock location
		in2ShowInventoryFrame = true,
		in2ReleaseInventoryFrame = true,
		in2DefaultMinimized = false,
		in2DefaultLocked = false,

		in2InventoryFrameScenes = {
			["bank"] = true,
			["guildBank"] =  true,
			["tradinghouse"] = true,
			["smithing"] = true,
			["store"] = true,
			["trade"] = true,
			["inventory"] = true
		},

		valLocked = false,
		valMinimized = false,
		valLastX = 0,
		valLastY = 0,
		valWideX = 0,

		in2InventoryFrameSceneSettings = {
			["bank"] = { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY},
			["guildBank"] =  { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY},
			["tradinghouse"] = { locked = valLocked, minimized = valMinimized, lastX = valWideX, lastY = valLastY},
			["smithing"] = { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY},
			["store"] = { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY},
			["stables"] = { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY},
			["trade"] = { locked = valLocked, minimized = valMinimized, lastX = valWideX, lastY = valLastY},
			["inventory"] = { locked = valLocked, minimized = valMinimized, lastX = valLastX, lastY = valLastY}
		},



		in2DefaultInventoryFrameView = "All",
		in2AgedGuildBankDataWarning = true,
--		in2TooltipsFont = "Universe57",
		in2TooltipsFontSize = 16,
		in2DefaultTooltipsMinimalPadding = false,
		in2IN2TooltipsMinimalPadding = false,
--		in2TooltipsShowWornIndicator = true,
	}
	local defaultData = in2_inventoryTable

	IIfA.currentCharacter = GetUnitName('player')
	IIfA.currentAccount = GetDisplayName()

	IIfA.settings = ZO_SavedVars:New("IIfA_Settings", 1, nil, default)
	IIfA.data = ZO_SavedVars:NewAccountWide("IIfA_Data", 1, "Data", defaultData)
	IIfA.colourHandler = ZO_ColorDef:New(IIfA.settings.in2TextColors)
	SLASH_COMMANDS["/ii"] = IIfA.IIfA_SlashCommands
	IIfA.IN2_RegisterForEvents()
	IIfA.IN2_UpdateGuildBankData() --Update account guildBanks (only add, doesn't remove)
	IIfA.IN2_RegisterForSceneChanges() -- register for callbacks on scene statechanges using user preferences or defaults
	IIfA.IN2_CreateSettingsWindow(IIfA.settings, defaultData)
	IIfA.IN2_SetDefaultTooltipHandlersV2()
	IIfA.IN2_SetupIN2InventoryBackpack(IIfA.settings.in2ShowInventoryFrame, IIfA.settings.in2ReleaseInventoryFrame) -- enable/disable inventory frame
	IIfA.IN2_CreateIN2ItemTooltipFrame()
	IIfA.IN2_CreateIN2PopupTooltipFrame()
end


function IIfA.IN2_DissectItemLink(itemLink)
--[[
Returns:	itemID
			itemText
			itemLevel
			itemQuality
			itemColor
			itemStyle
			itemType
			itemEnchantmentType
			itemEnchantmentStrength1
			itemEnchantmentStrength2
			itemIsBound
			itemIsStolen
			itemChargeStatus

Dissected parts
	ItemID		1
	unknown		2
	itemLevel	3
	itemQuality 4
	itemColor	5
	itemStyle	6
	itemType	7
	itemEnchantmentType			8
	itemEnchantmentStrength1	9
	itemEnchantmentStrength2	a
	unknown						b
	unknown						c
	unknown 1					d
	unknown 2					e
	unknown 3					f
	unknown 4					g
	itemIsBound					h
	itemIsStolen				i
	itemHealth/Charge			j
	unknown 7					k

		   	   1 2 3 4 5 6 7 8 9 a b c d e f g h i j k
lockpick normal/stolen
|H1:item:30357:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
|H1:item:30357:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0|h|h

voidstone helm - v13 normal/stolen
|H1:item:43562:272:50:0:0:0:0:0:0:0:0:0:0:0:0:5:0:0:0:10000:0|h|h
|H1:item:55480:271:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:1:10000:0|h|h

pauldron song of lamae vr12  damaged and normal
|H1:item:51993:257:50:26582:276:50:0:0:0:0:0:0:0:0:0:2:1:1:0:10000:0|h|h
|H1:item:51993:257:50:26582:276:50:0:0:0:0:0:0:0:0:0:2:1:1:0:5880:0|h|h

voidsteel cuirass of magicka, normal & stolen
|H1:item:45095:229:50:26582:229:50:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h
|H1:item:55482:265:50:26582:265:50:0:0:0:0:0:0:0:0:0:7:0:0:1:10000:0|h|h

bound comb, normal & stolen, both bound
|H1:item:61447:2:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0|h|h
|H1:item:61447:2:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0|h|h

staff of the song of lamae v12
|H1:item:52101:257:50:26844:276:50:0:0:0:0:0:0:0:0:0:8:1:1:0:87:0|h|h
|H1:item:52101:257:50:26844:276:50:0:0:0:0:0:0:0:0:0:8:1:1:0:492:0|h|h

staff of the song of lamae v9
|H1:item:51984:163:50:26844:161:50:0:0:0:0:0:0:0:0:0:8:1:1:0:112:0|h|h


Acai Berry - 4 diff entries
|H1:item:34349:25:23:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Acai Berry]|h - scream and panic guild bank, 69 count
|H1:item:34349:25:21:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Acai Berry]|h - peanut gallery guild bank, 63 count
|H1:item:34349:25:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Acai Berry]|h - peanut gallery guild bank, 200 count
|H1:item:34349:25:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Acai Berry]|h - pagan abby, 379 count



--]]
	if (itemLink) then
		local data = itemLink:match("|H.:item:(.-)|h.-|h")
		-- d(data)
		-- d(zo_strsplit(':', data))
		local itemID,
				_,
				itemLevel,
				itemEnchantmentType,
				itemEnchantmentStrength1,
				itemEnchantmentStrength2,
				_, _, _, _, _, _, _, _, _,
				itemStyle,
				_,
				itemIsBound,
				itemChargeStatus = zo_strsplit(':', data)

		local itemType = GetItemLinkItemType(itemLink)
		local itemText = GetItemLinkName(itemLink)
		local itemQuality = GetItemLinkQuality(itemLink)
		local itemColor = GetItemQualityColor(itemQuality):ToHex()
--		local itemCraftingType = GetItemLinkCraftingSkillType(itemLink)

		return itemID, itemText, itemLevel, itemQuality, itemColor, itemStyle, itemType, itemEnchantmentType, itemEnchantmentStrength1, itemEnchantmentStrength2, itemIsBound, itemChargeStatus
	else
		return nil
	end
end

function IIfA.GetItemID(itemLink)
	if (itemLink) then
		local data = itemLink:match("|H.:item:(.-)|h.-|h")
		-- d(data)
		-- d(zo_strsplit(':', data))
		local itemID = zo_strsplit(':', data)		-- just get the number

		-- because other functions may be comparing string to string, we can't make this be a number or it won't compare properly
		return itemID
	else
		return nil
	end
end

--[[
4-19-15 AM - function no longer needed
function IIfA.IN2_CompareLinksUsingPlayerPreference(itemLink1, itemLink2)
	local itemLink1ItemID, itemLink1ItemText, itemLink1ItemLevel, itemLink1ItemValue, itemLink1ItemColor = IIfA.IN2_DissectItemLink(itemLink1)
	local itemLink2ItemID, itemLink2ItemText, itemLink2ItemLevel, itemLink2ItemValue, itemLink2ItemColor = IIfA.IN2_DissectItemLink(itemLink2)

	local compareResult = (itemLink1ItemID == itemLink2ItemID)

	return compareResult
end
--]]

function IIfA.IN2_QueryAccountInventory(itemLink, itemName)

	local queryItem = {
		name = itemName,
		link = itemLink,
		locations = {},
	}
	-- try and generate an item name
	if queryItem.name == nil then
		if (zo_strformat("<<Z:1>>", itemName):find(zo_strformat("<<Z:1>>", queryItem.name)) ~= nil) then
			queryItem.name = zo_strformat("<<Z:1>>", itemName)
		else
			queryItem.name = GetItemLinkName(itemLink)
		end
	end

	local queryItemsFound = 0
	local AlreadySavedLoc = false
	local newLocation = {}
	local itemType

-- d(GetItemLinkItemType(itemLink))
	if GetItemLinkCraftingSkillType(itemLink) ~= CRAFTING_TYPE_INVALID then
		itemLink = IIfA.GetItemID(itemLink)
	else
		itemType = GetItemLinkItemType(itemLink)
		if itemType == ITEMTYPE_STYLE_MATERIAL or itemType == ITEMTYPE_ARMOR_TRAIT or itemType == ITEMTYPE_WEAPON_TRAIT or itemType == ITEMTYPE_LOCKPICK then
			itemLink = IIfA.GetItemID(itemLink)
		end
	end

	local item = IIfA.data.DBv2[itemLink]
	local itemName = itemLink


	-- the database holds all the information about the items. we need to get rid of this check. as soon as we have understood it.
	--for itemName, item in pairs(IIfA.data.DBv2) do
		if ((queryItem.link ~= nil) and (item ~= nil)) then
			if true then		-- (IIfA.IN2_CompareLinksUsingPlayerPreference(itemName, queryItem.link)) then -- if the query item has been found
				for locationName, location in pairs(item) do
					if (locationName ~= "attributes") then
						AlreadySavedLoc = false
						for x, QILocation in pairs(queryItem.locations) do
							if (QILocation.name == locationName)then
								QILocation.itemsFound = QILocation.itemsFound + location.itemCount
								AlreadySavedLoc = true
							end
						end
						if (not AlreadySavedLoc) and (location.itemCount > 0) then
							newLocation = {}
							newLocation.name = locationName
							newLocation.itemsFound = location.itemCount
							--newLocation.worn = location.worn
							table.insert(queryItem.locations, newLocation)
						end
					end
				end
			end
		end
	--end
	return queryItem
end


function IIfA.IN2_TooltipUpdateHandler(control, ...)
	local IN2_queryResults, location, locationName, itemsFound = nil
	local fontSettings = LMP:Fetch('font', IIfA.GetTooltipFont()) .. "|" .. IIfA.GetTooltipFontSize()
	local IN2_ProcessedAttribs = false
	-- local ItemTooltip = ItemTooltip
	-- local PopupTooltip = PopupTooltip
	-- local IN2_ITEM_TOOLTIP = IN2_ITEM_TOOLTIP
	-- local IN2_POPUP_TOOLTIP = IN2_POPUP_TOOLTIP
--[[
	if(IIfA.settings.in2ToggleIN2Tooltips) then
		d("IN2 TT Enabled")
	else
		d("IN2 TT Disabled")
	end
--]]

--	local worn = ""
	if ((IIfA.settings.in2ToggleDefaultTooltips and (control == PopupTooltip or control == ItemTooltip)) or
		(IIfA.settings.in2ToggleIN2Tooltips and (control == IN2_POPUP_TOOLTIP or control == IN2_ITEM_TOOLTIP))) then
		if (control == PopupTooltip or control == IN2_POPUP_TOOLTIP) then	--Handle PopupTooltips
			if (not control.IN2_HasModified) then
				IIfA.IN2_DebugOutput('[IIfA]:Updating Tooltip - PopupTooltip')
				IN2_ProcessedAttribs = IIfA.IN2_ProcessItemAttribs(control, control.lastLink)
				IN2_queryResults = IIfA.IN2_QueryAccountInventory(control.lastLink)
				if (IIfA.getTableLength(IN2_queryResults.locations) > 0) then
					IIfA.IN2_DebugOutput(control.lastLink)
					control:AddLine(" ")
					ZO_Tooltip_AddDivider(control)
					for x, location in pairs(IN2_queryResults.locations) do
--						worn = ""
--						if (location.worn and IIfA.settings.in2TooltipsShowWornIndicator)then
--							worn = "[Equiped] "
--						end
						IIfA.IN2_DebugOutput(location.name.." x"..location.itemsFound)
-- 2015-3-10 AssemblerManic - removed next line, changed to use fontSettings, removed worn indicator
--						control:AddLine(IIfA.colourHandler:Colorize(worn..location.name.." x"..location.itemsFound), LMP:Fetch('font', IIfA.settings.in2TooltipsFont).."|"..IIfA.GetTooltipFontSize())
						control:AddLine(IIfA.colourHandler:Colorize(location.name.." x"..location.itemsFound), fontSettings)
					end
				else
					IIfA.IN2_DebugOutput('[IIfA]:No matching items in DB.')
				end
				control.IN2_HasModified = true
			end
		elseif (control == ItemTooltip or control == IN2_ITEM_TOOLTIP) then	--Handle ItemTooltips
			if (not control.IN2_HasModified) then
				IIfA.IN2_DebugOutput('[IIfA]:Updating Tooltip - ItemTooltip')
				IN2_ProcessedAttribs = IIfA.IN2_ProcessItemAttribs(control, IN2_CURRENT_MOUSEOVER_LINK)
				IN2_queryResults = IIfA.IN2_QueryAccountInventory(IN2_CURRENT_MOUSEOVER_LINK)
				if (IIfA.getTableLength(IN2_queryResults.locations) > 0) then
					IIfA.IN2_DebugOutput(IN2_CURRENT_MOUSEOVER_LINK)
					if (IIfA.getTableLength(IN2_queryResults.locations) == 1 and IIfA.settings.in2HideRedundantInfo) then
						if (control == IN2_ITEM_TOOLTIP) then
							control:AddLine(" ")
							ZO_Tooltip_AddDivider(control)
						end
					else
						control:AddLine(" ")
						ZO_Tooltip_AddDivider(control)
					end
					for x, location in pairs(IN2_queryResults.locations) do
						locationName = location.name
						itemsFound = location.itemsFound

						IIfA.IN2_DebugOutput(locationName .. " x" .. itemsFound)
--						local worn = ""
--						if (location.worn and IIfA.settings.in2TooltipsShowWornIndicator)then
--							worn = "[Equiped] "
--						end
						--[[FR105 - v0.1.1 - Adding code]]--
						--[[Change: Adding code to handle IIfA.settings.in2HideRedundantInfo.]]--
						if (not IIfA.settings.in2HideRedundantInfo) then
-- 4-19-15 AM - removed worn indicator
--							control:AddLine(IIfA.GetColourHandler():Colorize(worn .. locationName .. " x" .. itemsFound), fontSettings)
							control:AddLine(IIfA.GetColourHandler():Colorize(locationName .. " x" .. itemsFound), fontSettings)
						else
							if (BANK:IsHidden() and IIfA.settings.in2HideRedundantInfo and locationName == IIfA.currentCharacter) then
								IIfA.IN2_DebugOutput("[IIfA]:HideRedundantInfo [On] - Skipping last entry.")
							elseif (BACKPACK:IsHidden() and IIfA.settings.in2HideRedundantInfo and locationName == "Bank") then
								IIfA.IN2_DebugOutput("[IIfA]:HideRedundantInfo [On] - Skipping last entry.")
							else
-- 4-19-15 AM - removed worn indicator
--								control:AddLine(IIfA.GetColourHandler():Colorize(worn .. locationName .. " x" .. itemsFound), fontSettings)
								control:AddLine(IIfA.GetColourHandler():Colorize(locationName .. " x" .. itemsFound), fontSettings)
							end
						end
						--[[END FR105]]--
					end
				else
					IIfA.IN2_DebugOutput('[IIfA]:No matching items in DB.')
				end
				control.IN2_HasModified = true
			end
			control.IN2_HasModified = true
		end
	end
	return IN2_queryResults, IN2_ProcessedAttribs	--Return function for Zgoo use to inspect data query results.
end

--[[ -- 2015-3-10 AssemblerManiac - remove DUPLICATE function block (directly above is other copy)
function IIfA.IN2_TooltipUpdateHandler(control, ...)
	local IN2_queryResults, location, locationName, itemsFound = nil
	local fontSettings = LMP:Fetch('font', IIfA.GetTooltipFont()).."|"..IIfA.GetTooltipFontSize()
	local IN2_ProcessedAttribs = false
	local ItemTooltip = ItemTooltip
	local PopupTooltip = PopupTooltip
	local IN2_ITEM_TOOLTIP = IN2_ITEM_TOOLTIP
	local IN2_POPUP_TOOLTIP = IN2_POPUP_TOOLTIP
	local worn = ""
	if ((IIfA.settings.in2ToggleDefaultTooltips and (control == PopupTooltip or control == ItemTooltip)) or (IIfA.settings.in2ToggleIN2Tooltips and  (control == IN2_POPUP_TOOLTIP or control == IN2_ITEM_TOOLTIP))) then
		if (control == PopupTooltip or control == IN2_POPUP_TOOLTIP) then	--Handle PopupTooltips
			if (not control.IN2_HasModified) then
				IIfA.IN2_DebugOutput('[IIfA]:Updating Tooltip - PopupTooltip')
				IN2_ProcessedAttribs = IIfA.IN2_ProcessItemAttribs(control, control.lastLink)
				IN2_queryResults = IIfA.IN2_QueryAccountInventory(control.lastLink)
				if (IIfA.getTableLength(IN2_queryResults.locations) > 0) then
					IIfA.IN2_DebugOutput(control.lastLink)
					control:AddLine(" ")
					ZO_Tooltip_AddDivider(control)
					for x, location in pairs(IN2_queryResults.locations) do
						-- worn = ""
						-- if (location.worn and IIfA.settings.in2TooltipsShowWornIndicator)then
							-- worn = "[Equiped] "
						-- end


						IIfA.IN2_DebugOutput(location.name.." x"..location.itemsFound)
						control:AddLine(IIfA.colourHandler:Colorize(worn..location.name.." x"..location.itemsFound), fontSettings)
					end
				else
					IIfA.IN2_DebugOutput('[IIfA]:No matching items in DB.')
				end
				control.IN2_HasModified = true
			end
		elseif (control == ItemTooltip or control == IN2_ITEM_TOOLTIP) then	--Handle ItemTooltips
			if (not control.IN2_HasModified) then
				IIfA.IN2_DebugOutput('[IIfA]:Updating Tooltip - ItemTooltip')
				IN2_ProcessedAttribs = IIfA.IN2_ProcessItemAttribs(control, IN2_CURRENT_MOUSEOVER_LINK)
				IN2_queryResults = IIfA.IN2_QueryAccountInventory(IN2_CURRENT_MOUSEOVER_LINK)
				if (IIfA.getTableLength(IN2_queryResults.locations) > 0) then
					IIfA.IN2_DebugOutput(IN2_CURRENT_MOUSEOVER_LINK)
					if (IIfA.getTableLength(IN2_queryResults.locations) == 1 and IIfA.settings.in2HideRedundantInfo) then
						if (control == IN2_ITEM_TOOLTIP) then
							control:AddLine(" ")
							ZO_Tooltip_AddDivider(control)
						end
					else
						control:AddLine(" ")
						ZO_Tooltip_AddDivider(control)
					end
					for x, location in pairs(IN2_queryResults.locations) do
						locationName = location.name
						itemsFound = location.itemsFound

						IIfA.IN2_DebugOutput(locationName .. " x" .. itemsFound)
						--local worn = ""
						-- if (location.worn and IIfA.settings.in2TooltipsShowWornIndicator)then
							-- worn = "[Equiped] "
						-- end
						-- FR105 - v0.1.1 - Adding code
						-- Change: Adding code to handle IIfA.settings.in2HideRedundantInfo.
						if (not IIfA.settings.in2HideRedundantInfo) then
							control:AddLine(IIfA.GetColourHandler():Colorize(worn .. locationName .." x".. itemsFound), fontSettings)
						else
							if (BANK:IsHidden() and IIfA.settings.in2HideRedundantInfo and locationName == IIfA.currentCharacter) then
								IIfA.IN2_DebugOutput("[IIfA]:HideRedundantInfo [On] - Skipping last entry.")
							elseif (BACKPACK:IsHidden() and IIfA.settings.in2HideRedundantInfo and locationName == "Bank") then
								IIfA.IN2_DebugOutput("[IIfA]:HideRedundantInfo [On] - Skipping last entry.")
							else
								control:AddLine(IIfA.GetColourHandler():Colorize(worn.. locationName .." x" ..itemsFound),fontSettings)
							end
						end
						-- END FR105
					end
				else
					IIfA.IN2_DebugOutput('[IIfA]:No matching items in DB.')
				end
				control.IN2_HasModified = true
			end
			control.IN2_HasModified = true
		end
	end
	return IN2_queryResults, IN2_ProcessedAttribs	--Return function for Zgoo use to inspect data query results.
end
--]] -- 2015-3-10 - end of block removal


function IIfA.IN2_ToolTipShowHandler(control, ...)
	if IIfA.settings.in2ToggleIN2Tooltips then
	local ItemTooltip = ItemTooltip
	local PopupTooltip = PopupTooltip
	local IN2_ITEM_TOOLTIP = IN2_ITEM_TOOLTIP
	local IN2_POPUP_TOOLTIP = IN2_POPUP_TOOLTIP
	if (IIfA.settings.in2ToggleDefaultTooltips) then
		IIfA.IN2_DebugOutput('[IIfA]:Tooltip Detected')
		control.IN2_HasModified = false
		local bag, index, curMouseOverLink, mouseOverControl, mocParent, parentName, parentIndex
		if (control == ItemTooltip) then
			mouseOverControl = moc()
			if (mouseOverControl ~= nil) then
	            mocParent = mouseOverControl:GetParent()

				if (mocParent)then

					parentName = mocParent:GetName()
					parentIndex = mouseOverControl.index

	                if (mouseOverControl.dataEntry and mouseOverControl.dataEntry.data.bagId and mouseOverControl.dataEntry.data.slotIndex) then --is inventroy
	                    curMouseOverLink = GetItemLink(mouseOverControl.dataEntry.data.bagId, mouseOverControl.dataEntry.data.slotIndex, LINK_STYLE_BRACKETS)
	                elseif (parentName == "ZO_Character") then --is worn item
	                    curMouseOverLink = GetItemLink(mouseOverControl.bagId, mouseOverControl.itemIndex, LINK_STYLE_BRACKETS)
	                elseif (parentName == "ZO_StoreWindowListContents") then --is store item
	                    curMouseOverLink = GetStoreItemLink(parentIndex, LINK_STYLE_BRACKETS)
	                elseif (parentName == "ZO_BuyBackListContents") or (parentName == "ZO_InteractWindowRewardArea")  then --is store item
	                    curMouseOverLink = GetBuybackItemLink(parentIndex, LINK_STYLE_BRACKETS)
	                elseif (parentName == "ZO_LootAlphaContainerListContents") then --is loot item
	                    curMouseOverLink = GetLootItemLink(mouseOverControl.dataEntry.data.lootId, LINK_STYLE_BRACKETS)
	                end
					IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink
	            end
			end
		end
	elseif (IIfA.settings.in2ToggleIN2Tooltips) then
		IIfA.IN2_DebugOutput('[IIfA]:Tooltip Detected')
		control.IN2_HasModified = false
		if (control == ItemTooltip) then
			IN2_ITEM_TOOLTIP:SetHidden(false)
		elseif (control == PopupTooltip) then
			IN2_POPUP_TOOLTIP:SetHidden(false)
		end
	end
	end
end

function IIfA.IN2_ToolTipHideHandler(control, ...)
	local ItemTooltip = ItemTooltip
	local PopupTooltip = PopupTooltip
	local IN2_ITEM_TOOLTIP = IN2_ITEM_TOOLTIP
	local IN2_POPUP_TOOLTIP = IN2_POPUP_TOOLTIP
	if (IIfA.settings.in2ToggleDefaultTooltips) then
		IIfA.IN2_DebugOutput('[IIfA]:Tooltip Closed')
		control.IN2_HasModified = false
		if (control == ItemTooltip) then
			IN2_CURRENT_MOUSEOVER_LINK = nil
		end
	elseif (IIfA.settings.in2ToggleIN2Tooltips) then
		IIfA.IN2_DebugOutput('[IIfA]:Tooltip Closed')
		control.IN2_HasModified = false
		if (control == ItemTooltip) then
			IN2_ITEM_TOOLTIP:SetHidden(true)
		elseif (control == PopupTooltip) then
			IN2_POPUP_TOOLTIP:SetHidden(true)
		end
	end
end

function IIfA.IN2_ToolTipAddGameDataHandler(control, ...)
	local ItemTooltip = ItemTooltip
	local PopupTooltip = PopupTooltip
	local IN2_ITEM_TOOLTIP = IN2_ITEM_TOOLTIP
	local IN2_POPUP_TOOLTIP = IN2_POPUP_TOOLTIP
	if (IIfA.settings.in2ToggleDefaultTooltips) then
	local bag, index, curMouseOverLink, mouseOverControl = nil
		IIfA.IN2_DebugOutput('[IIfA]:Tooltip Changed')
		control.IN2_HasModified = false
		mouseOverControl = moc()
		if (mouseOverControl ~= nil) then
			if (mouseOverControl.dataEntry) then
				bag = mouseOverControl.dataEntry.data.bagId
				index = mouseOverControl.dataEntry.data.slotIndex
				curMouseOverLink = GetItemLink(bag, index, LINK_STYLE_BRACKETS)
				IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink
			elseif (mouseOverControl.bagId and mouseOverControl.itemIndex) then
				bag = mouseOverControl.bagId
				index = mouseOverControl.itemIndex
				curMouseOverLink = GetItemLink(bag, index, LINK_STYLE_BRACKETS)
				IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink
			end
		end
	elseif (IIfA.settings.in2ToggleIN2Tooltips) then
		if (control == ItemTooltip) then
			IN2_ITEM_TOOLTIP:SetHidden(false)
		elseif (control == PopupTooltip) then
			IN2_POPUP_TOOLTIP:SetHidden(false)
		end
	end
end

function IIfA.IN2_SetDefaultTooltipHandlersV2()
		--PopupTooltips
		ZO_PreHookHandler(PopupTooltip, 'OnShow', IIfA.IN2_ToolTipShowHandler)
		ZO_PreHookHandler(PopupTooltip, 'OnUpdate', IIfA.IN2_TooltipUpdateHandler)
		ZO_PreHookHandler(PopupTooltip, 'OnHide', IIfA.IN2_ToolTipHideHandler)
		ZO_PreHookHandler(PopupTooltip, 'OnAddGameData', IIfA.IN2_ToolTipAddGameDataHandler)

		--ItemTooltips
		ZO_PreHookHandler(ItemTooltip, 'OnShow', IIfA.IN2_ToolTipShowHandler)
		ZO_PreHookHandler(ItemTooltip, 'OnUpdate', IIfA.IN2_TooltipUpdateHandler)
		ZO_PreHookHandler(ItemTooltip, 'OnHide', IIfA.IN2_ToolTipHideHandler)
		ZO_PreHookHandler(ItemTooltip, 'OnAddGameData', IIfA.IN2_ToolTipAddGameDataHandler)
end

function IIfA.IN2_RegisterForSceneChanges(scene, enable)
	local sceneList = {
		"inventory",
		"bank",
		"guildBank",
		"tradinghouse",
		"smithing",
		"store",
		"trade",
	}

	for i, sceneName in ipairs(sceneList) do
		local scene = SCENE_MANAGER:GetScene(sceneName)
		scene:RegisterCallback("StateChange", function(...)
			IIfA.IN2_ToggleInventoryFrame(scene, ...)
		end)
	end
end

function IIfA.IN2_ToggleInventoryFrame(control, oldState, newState)
	IIfA.IN2_DebugOutput("Scene Fired: " .. control.name)
	if (IIfA.settings.in2ShowInventoryFrame) then
		if (newState == SCENE_SHOWING) then
			if (IIfA.settings.in2InventoryFrameScenes[control.name]) then
				if (not IIfA.settings.in2ReleaseInventoryFrame) then 	--docked
					IN2_INVENTORY_FRAME.ActiveScene = control.name
					IN2_INVENTORY_FRAME:LoadFrameSceneLocation()
					if (control.name ~= "inventory" and control.name ~= "smithing") then
						ZO_SharedThinLeftPanelBackground:SetHidden(false)
						ZO_SharedThinLeftPanelBackground:SetWidth(IN2_INVENTORY_FRAME:GetWidth() + 30)
					else
        				ZO_SharedThinLeftPanelBackground:SetWidth(240 + IN2_INVENTORY_FRAME:GetWidth() - 15)
						IN2_INVENTORY_FRAME:LoadFrameSceneLocation()
						IN2_INVENTORY_FRAME:SetHidden(false)
					end
					IN2_INVENTORY_FRAME:SetHidden(false)
					ZO_SharedThinLeftPanelBackgroundRight:SetHeight(LEFTPANEL_NEW_HEIGHT)
					ZO_SharedThinLeftPanelBackgroundLeft:SetHeight(LEFTPANEL_NEW_HEIGHT)

				else 	--undocked
					IN2_INVENTORY_FRAME.ActiveScene = control.name
					IN2_INVENTORY_FRAME:LoadFrameSceneLocation()
					IN2_INVENTORY_FRAME:SetHidden(false)
					ZO_SharedThinLeftPanelBackground:SetHidden(false)
					if (control.name ~= "inventory" and control.name ~= "smithing") then
						ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(true)
						ZO_SharedThinLeftPanelBackgroundRight:SetHidden(true)
					else
						ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(false)
						ZO_SharedThinLeftPanelBackgroundRight:SetHidden(false)
					end
				end
			else
				IN2_INVENTORY_FRAME:SetHidden(true)
				if (control.name == "inventory" or control.name == "smithing") then
					ZO_SharedThinLeftPanelBackground:SetWidth(240)
					ZO_SharedThinLeftPanelBackground:SetHidden(false)
				else
					ZO_SharedThinLeftPanelBackground:SetHidden(true)
					ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(false)
					ZO_SharedThinLeftPanelBackgroundRight:SetHidden(false)
				end
			end
		elseif (newState == SCENE_HIDING) then
			if (IIfA.settings.in2InventoryFrameScenes[control.name]) then
				if (not IIfA.settings.in2ReleaseInventoryFrame and control.name ~= "inventory" and control.name ~= "smithing") then
					ZO_SharedThinLeftPanelBackground:SetWidth(240 + IN2_INVENTORY_FRAME:GetWidth() - 15)
					ZO_SharedThinLeftPanelBackground:SetHidden(true)
				elseif (control.name ~= "inventory" and control.name ~= "smithing") then
					IN2_INVENTORY_FRAME:SaveFrameSceneLocation()
					ZO_SharedThinLeftPanelBackground:SetHidden(true)
					ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(false)
					ZO_SharedThinLeftPanelBackgroundRight:SetHidden(false)
				else
					IN2_INVENTORY_FRAME:SaveFrameSceneLocation()
				end
				IN2_INVENTORY_FRAME.ActiveScene = ""
			else
				IN2_INVENTORY_FRAME:SetHidden(true)
				if (control.name == "inventory" or control.name == "smithing") then
					ZO_SharedThinLeftPanelBackground:SetWidth(240)
					ZO_SharedThinLeftPanelBackground:SetHidden(false)
				else
					ZO_SharedThinLeftPanelBackground:SetHidden(true)
					ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(false)
					ZO_SharedThinLeftPanelBackgroundRight:SetHidden(false)
				end
			end
			ZO_SharedThinLeftPanelBackgroundRight:SetHeight(LEFTPANEL_ORIGINAL_HEIGHT)
			ZO_SharedThinLeftPanelBackgroundLeft:SetHeight(LEFTPANEL_ORIGINAL_HEIGHT)
		end
	end
end

function IIfA.IIfA_SlashCommands(cmd)

	if (cmd == "") then
    	d("[IIfA]:Please find the majority of options in the addon settings section of the menu under Inventory Insight From Ashes.")
    	d(" ")
    	d("[IIfA]:Usage - ")
    	d("	/IIfA [options]")
    	d(" 	")
    	d("	Options")
    	d("		debug - Enables debug functionality for the IIfA addon.")
    	d("		run - Runs the IIfA data collector.")
		d("		color - Opens the color picker dialog to set tooltip text color.")
		d("		hideRedundantInfo - Enables/Disables the inventory information added to Tooltips and data collection..")
		d("		export - Exports data collection..")
		return
	end

	if (cmd == "debug") then
		if (IIfA.settings.in2Debug) then
			d("[IIfA]:Debug[Off]")
			IIfA.settings.in2Debug = false
		else
			d("[IIfA]:Debug[On]")
			IIfA.settings.in2Debug = true
		end
		return
	end

	if (cmd == "run") then
		d("[IIfA]:Running collector...")
		IIfA.CollectAll()
		return
	end

	if (cmd == "color") then
		local in2ColorPickerOnMouseUp = _in2OptionsColorPicker:GetHandler("OnMouseUp")
		in2ColorPickerOnMouseUp(_in2OptionsColorPicker, nil, true)
		return
	end

	if (cmd == "hideRedundantInfo") then
		if (IIfA.settings.in2HideRedundantInfo) then
			d("[IIfA]:HideRedundantInfo[Off]")
			IIfA.settings.in2HideRedundantInfo = false
		else
			d("[IIfA]:HideRedundantInfo[On]")
			IIfA.settings.in2HideRedundantInfo = true
		end
		return
	end

	if (cmd == "export") then
		IIfA.IN2_DataToCSV()
	end
end



--function IIfA.IN2_CreateSettingsWindow()

	-- LAM:AddDescription(LAM_vicstersAddons, "_in2GeneralSettings", "General configuration settings for Inventory Insight.", "|cc5c29eGeneral Settings|r")



	-- LAM:AddDescription(LAM_vicstersAddons, "_in2OptionsInventoryFrameSettings", "The IIfA frame provides visual access and searchability to your entire account-wide inventory. The Inventory Frame docks into the Character Frame (left side) and is configurable to be visibile in a range of scenes listed below. You can also choose to undock the frame from the default UI to move it.", "|cc5c29eInventory Frame Settings|r")

	-- LAM:AddDescription(LAM_vicstersAddons, "_in2OptionsInventoryFrameScenes", "Select the scenes below that you want the Inventory Frame to be visible in.", "|cc5c29eAvailable Inventory Frame Scenes|r")

	--LAM:RegisterOptionControls(IIfA.Name, optionsData)

	-- watermark = WINDOW_MANAGER:CreateControl(nil,_vicstersAddons_IN2Header,CT_TEXTURE)
    -- watermark:SetDimensions(95,95)
    -- watermark:SetAnchor(TOP, _vicstersAddons_IN2HeaderLabel, BOTTOM, 0, -10)
    -- watermark:SetTexture("IIfA/assets/inventoryinsight_icon.dds") -- texture will toggle based on current sort
    -- watermark:SetTextureCoords(0,1,0,1)
    -- watermark:SetAlpha(1)


--end



function IIfA.IIfA_Initialized()
	EVENT_MANAGER:RegisterForEvent("IIfALoaded", EVENT_ADD_ON_LOADED, IIfA.IIfA_Loaded)
end

IIfA.IIfA_Initialized()
