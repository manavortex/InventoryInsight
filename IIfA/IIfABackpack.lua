local IIfA = IIfA

local LMP = LibStub("LibMediaProvider-1.0")

IIfA.ScrollSortUp = true
IIfA.ActiveFilter = 0
IIfA.ActiveSubFilter = 0
IIfA.InventoryFilter = "All"

IIfA.InventoryListFilter = "Any"
IIfA.InventoryListFilterQuality = 99


-- this is for the buttons
local function enableFilterButton(num)
	local buttonName = "Button"..num
    local button = IIFA_GUI_Header_Filter:GetNamedChild(buttonName)
    if button then
        button:SetState(BSTATE_PRESSED)
    end
end
local function disableFilterButton(num)
    local button = IIFA_GUI_Header_Filter:GetNamedChild("Button"..num)
    if button then
        button:SetState(BSTATE_NORMAL)
    end
end

function IIfA:GetActiveFilter()
	if not IIfA.ActiveFilter then return 0 end
	return tonumber(IIfA.ActiveFilter)
end

function IIfA:SetActiveFilter(value)
	if value == nil then
		value = 0
	else
		value = tonumber(value)
	end
	local currentFilter = IIfA:GetActiveFilter()

	if tonumber(currentFilter) == value then
		value = 0
	end

	IIfA.ActiveFilter = value
	if currentFilter ~= value then
		disableFilterButton(currentFilter)
	end

	enableFilterButton(value)

	IIfA:UpdateScrollDataLinesData()
	IIfA:UpdateInventoryScroll()
end

function IIfA:GetActiveSubFilter()
	if not IIfA.activeSubFilter then return 0 end
	return tonumber(IIfA.activeSubFilter)
end

function IIfA:SetActiveSubFilter(value)
	value = tonumber(value)
	if IIfA.GetActiveSubFilter() == value then
		IIfA.activeSubFilter = 0
	else
		IIfA.activeSubFilter = value
	end
	IIfA:UpdateScrollDataLinesData()
	IIfA:UpdateInventoryScroll()
end



--[[----------------------------------------------------------------------]]
--[[----------------------------------------------------------------------]]
--[[------ GUI functions  ------------------------------------------------]]

function IIfA:GUIDoubleClick(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT and control.itemLink then
		if control.itemLink ~= "" then
			ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. zo_strformat(SI_TOOLTIP_ITEM_NAME, control.itemLink))
		end
	end
end

local function getItemLinkFromDB(itemLink, item)
	local iLink = ""
	if zo_strlen(itemLink) < 10 then
		iLink = item.itemLink
	else
		iLink = itemLink
	end
	return iLink
end

local function getHouseIds()
	local ret = {}
	for houseName, houseId in pairs(IIfA:GetTrackedHouses()) do
		table.insert(ret, houseId)
	end
	return ret
end


local function DoesInventoryMatchList(locationName, location)
	local bagId 	= location.bagID
	local filter 	= IIfA.InventoryListFilter
	
	local function isHouse()
		return IIfA:GetTrackingWithHouseNames()[locationName]
	end
	
	local function isOneOf(value, comp1, comp2, comp3, comp4, comp5, comp6)
		return nil ~= value and (value == comp6) or (value == comp5) or (value == comp4) or (value == comp3) or (value == comp2) or value == comp1 
	end
	
--	if locationName == "attributes" then return false end
	if (filter == "All") then
		return true

	elseif (filter == "All Banks") then
		return isOneOf(bagId, BAG_SUBSCRIBER_BANK, BAG_GUILDBANK) and IIfA.trackedBags[bagId]

	elseif (filter == "All Guild Banks") then
		return isOneOf(bagId, BAG_GUILDBANK)

	elseif (filter == "All Characters") then
		return isOneOf(bagId, BAG_BACKPACK, BAG_WORN)

	elseif (filter == "Bank and Characters") then
		return isOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_BACKPACK, BAG_WORN)

	elseif(filter == "Bank and Current Character") then
		return isOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_BACKPACK, BAG_WORN) 
			and locationName == IIfA.currentCharacterId
				 
	elseif(filter == "Bank and other characters") then
		return isOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_BACKPACK, BAG_WORN) 
			and locationName ~= IIfA.currentCharacterId

	elseif(filter == "Bank Only") then
		return isOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK)

	elseif(filter == "Craft Bag") then
		return (bagId == BAG_VIRTUAL)
	
	elseif(filter == "Housing Storage") then
		return nil ~= GetCollectibleForHouseBankBag and GetCollectibleForHouseBankBag(bagId) > 0 
		
	elseif(filter == "All Houses") then
		return IIfA.data.collectHouseData[bagId]
		
	elseif(nil ~= IIfA:GetTrackingWithHouseNames()[filter]) then
		return (bagId == IIfA:GetHouseIdFromName(filter))
		
	else --Not a preset, must be a specific guildbank or character
		if isOneOf(bagId, BAG_BACKPACK, BAG_WORN) then
			-- it's a character name, convert to Id, check that against location Name in the dbv3 table
			if locationName == IIfA.CharNameToId[filter] then return true end
		else
			-- it's a bank to compare, do it direct
			return locationName == filter
		end
	end
end

local function matchCurrentInventory(locationName)
--	if locationName == "attributes" then return false end
	local accountInventoryList = IIfA:GetAccountInventoryList()

	for i, inventoryName in ipairs(accountInventoryList) do
		if inventoryName == locationName then return true end
	end

	return (IIfA:GetInventoryListFilter() == "All")
end

local qualityDictionary
local function getColoredString(color, s)
	local c = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, color))
	return c:Colorize(s)
end
local function getQualityDict()

	if nil == qualityDictionary then
		qualityDictionary = {}
		qualityDictionary["Any"] = 99
		qualityDictionary[getColoredString(ITEM_QUALITY_TRASH,  "Junk")] 			= ITEM_QUALITY_TRASH
		qualityDictionary[getColoredString(ITEM_QUALITY_NORMAL, "Normal")] 			= ITEM_QUALITY_NORMAL
		qualityDictionary[getColoredString(ITEM_QUALITY_MAGIC,  "Magic")] 			= ITEM_QUALITY_MAGIC
		qualityDictionary[getColoredString(ITEM_QUALITY_ARCANE, "Arcane")] 			= ITEM_QUALITY_ARCANE
		qualityDictionary[getColoredString(ITEM_QUALITY_ARTIFACT, "Artifact")] 		= ITEM_QUALITY_ARTIFACT
		qualityDictionary[getColoredString(ITEM_QUALITY_LEGENDARY, "Legendary")] 	= ITEM_QUALITY_LEGENDARY		
	end
	return qualityDictionary
end

local function matchFilter(itemName, itemLink)
    local ret = true
	local itemMatch = false
	local hasSetInfo, setName

	local searchFilter = IIfA.searchFilter
	-- 17-7-30 AM - moved lowercasing to when it's created, one less call to lowercase for every item
	
    local name = string.lower(itemName) or ""

	-- text filter takes precedence
	-- 3-6-17 AM - you're either filtering on a set name, or not - much less confusing (hopefully)
	if IIfA.bFilterOnSetName then
		hasSetInfo, setName = GetItemLinkSetInfo(itemLink, false)
		if hasSetInfo then
			ret = zo_plainstrfind(setName:lower(), searchFilter)
		else
			-- no point in going any further, this item doesn't have set info at all, so return a fail and keep truckin
			return false
		end
	else
		ret = zo_plainstrfind(name, searchFilter)
		if IIfA:GetSettings().bFilterOnSetNameToo then
			hasSetInfo, setName = GetItemLinkSetInfo(itemLink, false)
			if hasSetInfo then
				ret = zo_plainstrfind(setName:lower(), searchFilter) or ret
			end
		end
	end

	local bWorn = false
	local equipType = 0
	local itemType = 0
	local itemQuality = ITEM_QUALITY_NORMAL
	local subType

	if IIfA.filterGroup ~= "All" and ret then		-- it's not everything, and text search matches, filter by some more stuff
		if IIfA.filterGroup == "Weapons" or
			IIfA.filterGroup == "Consumable" or
			IIfA.filterGroup == "Materials" or
			IIfA.filterGroup == "Misc" or
			IIfA.filterGroup == "Specialized" or
			IIfA.filterGroup == "Body" then
			if IIfA.filterGroup == "Weapons" then
				itemType = GetItemLinkWeaponType(itemLink)
			elseif IIfA.filterGroup == "Body" then
				-- Body takes extra arg at beginning of array, if array is used at all
				-- Item type (armor, non-armor)
				-- remaining args are the specific type of equipment
				itemType = 0
				_, _, _, equipType = GetItemLinkInfo(itemLink)
				-- pre-qual any body type item, if it's not wearable, it's not included

				if equipType == EQUIP_TYPE_INVALID or
					equipType == EQUIP_TYPE_POISON or
					equipType == EQUIP_TYPE_MAIN_HAND or
					equipType == EQUIP_TYPE_ONE_HAND or
					equipType == EQUIP_TYPE_TWO_HAND then
					itemType = 0
				elseif IIfA.filterTypes == nil then		-- if we're not searching for something specific
					-- quit searching, we're displaying anything worn
					itemType = 1		-- number doesn't matter
				else
					-- it's a wearable piece of some type
					bWorn = true
					itemType = GetItemLinkArmorType(itemLink)
				end
			elseif	IIfA.filterGroup == "Consumable" or
					IIfA.filterGroup == "Materials" or
					IIfA.filterGroup == "Specialized" or
					IIfA.filterGroup == "Misc" then
				itemType, subType = GetItemLinkItemType(itemLink)
				if IIfA.filterGroup ~= "Specialized" then
					subType = nil
				end
			end

			if itemType == 0 and not bWorn then		-- it's not worn or armor and no type assigned, ret false
				ret = false
			else
				if IIfA.filterTypes ~= nil then
					if bWorn then
						if itemType == IIfA.filterTypes[1] then
							for i=2, #IIfA.filterTypes do
								if(equipType == IIfA.filterTypes[i]) then
									itemMatch = true
									break
								end
							end
						end
					elseif IIfA.filterGroup == "Specialized" then
						if itemType == IIfA.filterTypes[1] then
							for i=2, #IIfA.filterTypes do
								if(subType == IIfA.filterTypes[i]) then
									itemMatch = true
									break
								end
							end
						end
					else
						for i=1, #IIfA.filterTypes do
							if (subType == nil and itemType == IIfA.filterTypes[i]) or
							   (subType ~= nil and subType == IIfA.filterTypes[i]) then
								itemMatch = true
								break
							end
						end
					end
				else
					itemMatch = true
				end
				ret = ret and itemMatch
			end
		elseif IIfA.filterGroup == "Stolen" then
			ret = ret and IsItemLinkStolen(itemLink)
		end
	end
    return ret
end
local function matchQuality(itemQuality)
	local quality = IIfA.InventoryListFilterQuality
	return 99 == quality or itemQuality == quality
end

--sort datalines
local function IIfA_FilterCompareUp(a, b)
	--local _, _, name1 = a.itemLink:match("|H(.-):(.-)|h(.-)|h")
	--local _, _, name2 = b.itemLink:match("|H(.-):(.-)|h(.-)|h")
	local name1 = a.name
	local name2 = b.name
	return (name1 or "") < (name2 or "")
end
local function IIfA_FilterCompareDown(a, b)
	return IIfA_FilterCompareUp(b, a)
end

local function sort(dataLines)
	if dataLines == nil then dataLines = IIFA_GUI_ListHolder.dataLines end

	if (IIfA.ScrollSortUp) then
		dataLines = table.sort(dataLines, IIfA_FilterCompareUp)
	elseif (not IIfA.ScrollSortUp) then
		dataLines = table.sort(dataLines, IIfA_FilterCompareDown)
	end
end

-- fill the shown item list with items that match current filter(s)
function IIfA:UpdateScrollDataLinesData()
	IIfA:DebugOut("UpdateScrollDataLinesData")

	if (not IIfA.searchFilter) or IIfA.searchFilter == "Click to search..." then
		IIfA.searchFilter = IIFA_GUI_SearchBox:GetText()
	end

	local index = 0
	local dataLines = {}
	local DBv3 = IIfA.database
	local iLink, itemLink, iconFile, itemQuality, tempDataLine = nil
	local itemTypeFilter, itemCount = 0
	local match = false
	local bWorn = false

	if(DBv3)then
		for itemLink, item in pairs(DBv3) do
			iLink = getItemLinkFromDB(itemLink, item)

			if (itemLink ~= "") then

				itemTypeFilter = 0
				if (item.filterType) then
					itemTypeFilter = item.filterType
				end

				itemCount = 0
				bWorn = false
				local itemIcon = GetItemLinkIcon(iLink)

				local locationName, locData
				for locationName, locData in pairs(item.locations) do
					itemCount = itemCount + (locData.itemCount or 0)
					if DoesInventoryMatchList(locationName, locData) then
						match = true
					end
					bWorn = bWorn or (locData.bagID == BAG_WORN)
				end
				tempDataLine = {
					link = iLink, 		-- getItemLinkFromDB(itemLink, item),
					qty = itemCount,
					icon = itemIcon,
					name = item.itemName,
					quality = item.itemQuality,
					filter = itemTypeFilter,
					worn = bWorn
				}

				if(itemCount > 0) and matchFilter(item.itemName, iLink) and matchQuality(item.itemQuality) and match then
					table.insert(dataLines, tempDataLine)
				end
				match = false
			end
		end
	end

	IIFA_GUI_ListHolder.dataLines = dataLines
	sort(IIFA_GUI_ListHolder.dataLines)
	IIFA_GUI_ListHolder.dataOffset = 0
	
end


local function fillLine(curLine, curItem)
	if curItem == nil then
		curLine.itemLink = ""
		curLine.icon:SetTexture(nil)
		curLine.icon:SetAlpha(0)
		curLine.text:SetText("")
		curLine.qty:SetText("")
		curLine.worn:SetHidden(true)
		curLine.stolen:SetHidden(true)
	else
		local r, g, b, a = 255, 255, 255, 1
		if (curItem.quality) then
			color = GetItemQualityColor(curItem.quality)
			r, g, b, a = color:UnpackRGBA()
		end
		curLine.itemLink = curItem.link
		curLine.icon:SetTexture(curItem.icon)
		curLine.icon:SetAlpha(1)
		local text = zo_strformat(SI_TOOLTIP_ITEM_NAME, curItem.name)
		curLine.text:SetText(text)
		curLine.text:SetColor(r, g, b, a)
		curLine.qty:SetText(curItem.qty)
		curLine.worn:SetHidden(not curItem.worn)
		curLine.stolen:SetHidden(not IsItemLinkStolen(curItem.link))
	end
end

function IIfA:InitializeInventoryLines()
	IIfA:DebugOut("InitializeInventoryLines")

	local curLine, curData
	for i = 1, IIFA_GUI_ListHolder.maxLines do

		curLine = IIFA_GUI_ListHolder.lines[i]
		curData = IIFA_GUI_ListHolder.dataLines[IIFA_GUI_ListHolder.dataOffset + i]
		IIFA_GUI_ListHolder.lines[i] = curLine

		if( curData ~= nil) then
			fillLine(curLine, curData)
		else
			fillLine(curLine, nil)
		end
	end
end

function IIfA:UpdateInventoryScroll()
	local index = 0

	IIfA:DebugOut("UpdateInventoryScroll")

	------------------------------------------------------
	if IIFA_GUI_ListHolder.dataOffset < 0 then IIFA_GUI_ListHolder.dataOffset = 0 end
	if IIFA_GUI_ListHolder.maxLines == nil then
		IIFA_GUI_ListHolder.maxLines = 35
	end
	IIfA:InitializeInventoryLines()

	local total = #IIFA_GUI_ListHolder.dataLines - IIFA_GUI_ListHolder.maxLines
	IIFA_GUI_ListHolder_Slider:SetMinMax(0, total)
end


function IIfA:SetItemCountPosition()
	for i=1, IIFA_GUI_ListHolder.maxLines do
		line = IIFA_GUI_ListHolder.lines[i]
		line.text:ClearAnchors()
		line.qty:ClearAnchors()
		if IIfA:GetSettings().showItemCountOnRight then
			line.qty:SetAnchor(TOPRIGHT, line, TOPRIGHT, 0, 0)
			line.text:SetAnchor(TOPLEFT, line:GetNamedChild("Button"), TOPRIGHT, 18, 0)
			line.text:SetAnchor(TOPRIGHT, line.qty, TOPLEFT, -10, 0)
		else
			line.qty:SetAnchor(TOPLEFT, line:GetNamedChild("Button"), TOPRIGHT, 8, -3)
			line.text:SetAnchor(TOPLEFT, line.qty, TOPRIGHT, 18, 0)
			line.text:SetAnchor(TOPRIGHT, line, TOPLEFT, 0, 0)
		end
	end
end


function IIfA:CreateLine(i, predecessor, parent)
	local line = WINDOW_MANAGER:CreateControlFromVirtual("IIFA_ListItem_".. i, parent, "IIFA_SlotTemplate")

	line.icon = line:GetNamedChild("Button"):GetNamedChild("Icon")
	line.text = line:GetNamedChild("Name")
	line.qty = line:GetNamedChild("Qty")
	line.worn = line:GetNamedChild("IconWorn")
	line.stolen = line:GetNamedChild("IconStolen")

--	line.text:SetText(text)
--	line.itemLink = text
--	text=""

	line:SetHidden(false)
	line:SetMouseEnabled(true)
	line:SetHeight(IIFA_GUI_ListHolder.rowHeight)

	if i == 1 then
		line:SetAnchor(TOPLEFT, IIFA_GUI_ListHolder, TOPLEFT, 0, 0)
		line:SetAnchor(TOPRIGHT, IIFA_GUI_ListHolder, TOPRIGHT, 0, 0)
	else
		line:SetAnchor(TOPLEFT, predecessor, BOTTOMLEFT, 0, 0)
		line:SetAnchor(TOPRIGHT, predecessor, BOTTOMRIGHT, 0, 0)
	end

	line:SetHandler("OnMouseEnter", function(self) IIfA:GuiLineOnMouseEnter(self) end )
	line:SetHandler("OnMouseExit", function(self) IIfA:GuiLineOnMouseExit(self) end )
	line:SetHandler("OnMouseDoubleClick", function(...) IIfA:GUIDoubleClick(...) end )

	return line
end


function IIfA:CreateInventoryScroll()
	IIfA:DebugOut("CreateInventoryScroll")

	IIFA_GUI_ListHolder.dataOffset = 0

	IIFA_GUI_ListHolder.dataLines = {}
	IIFA_GUI_ListHolder.lines = {}
	IIFA_GUI_Header_SortBar.Icon = IIFA_GUI_Header_SortBar:GetNamedChild("_Sort"):GetNamedChild("_Icon")

	--local width = 250 -- IIFA_GUI_ListHolder:GetWidth()
	local text = "       No Collected Data"


	-- we set those to 35 because that's the amount of lines we can show
	-- within the dimension constraints
	IIFA_GUI_ListHolder.maxLines = 35
	local predecessor = nil
	for i=1, IIFA_GUI_ListHolder.maxLines do
		IIFA_GUI_ListHolder.lines[i] = IIfA:CreateLine(i, predecessor, IIFA_GUI_ListHolder)
		predecessor = IIFA_GUI_ListHolder.lines[i]
	end

	if IIfA:GetSettings().showItemCountOnRight then
		IIfA:SetItemCountPosition()
	end

	-- setup slider
	--	local tex = "/esoui/art/miscellaneous/scrollbox_elevator.dds"
	--	IIFA_GUI_ListHolder_Slider:SetThumbTexture(tex, tex, tex, 16, 50, 0, 0, 1, 1)
	IIFA_GUI_ListHolder_Slider:SetMinMax(0, #IIFA_GUI_ListHolder.dataLines - IIFA_GUI_ListHolder.maxLines)

	return IIFA_GUI_ListHolder.lines
end

function IIfA:GetCharacterList()
	local charInventories = {}
	for i=1, GetNumCharacters() do
		local charName, _, _, _, _, _, _, _ = GetCharacterInfo(i)
		charName = charName:sub(1, charName:find("%^") - 1)
		if (nil == charInventories[charName]) then 
			table.insert(charInventories, charName)
		end
	end
	return charInventories
end

function IIfA:GetAccountInventoryList()
	local accountInventories = IIfA.dropdownBankNames
	

-- get character names, will present in same order as character selection screen
	for idx, charName in ipairs(IIfA:GetCharacterList()) do
		if (nil == accountInventories[charName]) then 
			table.insert(accountInventories, charName)
		end
	end
	
-- banks are same as toons, same order as player normally sees them
	if IIfA.data.bCollectGuildBankData then
		for i = 1, GetNumGuilds() do
			id = GetGuildId(i)
			guildName = GetGuildName(id)

			-- on the off chance that this doesn't exist already, create it
			if IIfA.data.guildBanks == nil then
				IIfA.data.guildBanks = {}
			end
			
			if IIfA.data.guildBanks[guildName] ~= nil then
				table.insert(accountInventories, guildName)
			end
		end
	end
	
	if IIfA.data.b_collectHouses then
		table.insert(accountInventories, "All Houses")
		for idx, houseName in ipairs(IIfA:GetTrackedHouseNames()) do
			table.insert(accountInventories, houseName)
		end
	end
	
	return accountInventories
end

function IIfA:QueryAccountInventory(itemLink)
	if itemLink ~= nil then
		itemLink = string.gsub(itemLink, '|H0', '|H1')
	end

	local queryItem = {
		link = itemLink,
		locations = {},
	}

	local queryItemsFound = 0
	local AlreadySavedLoc = false
	local newLocation = {}

	itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_BLACKSMITHING_MATERIAL or
		itemType == ITEMTYPE_ARMOR_TRAIT or
		itemType == ITEMTYPE_BLACKSMITHING_BOOSTER or
		itemType == ITEMTYPE_BLACKSMITHING_RAW_MATERIAL or
		itemType == ITEMTYPE_CLOTHIER_BOOSTER or
		itemType == ITEMTYPE_CLOTHIER_MATERIAL or
		itemType == ITEMTYPE_CLOTHIER_RAW_MATERIAL or
		itemType == ITEMTYPE_ENCHANTING_RUNE_ASPECT or
		itemType == ITEMTYPE_ENCHANTING_RUNE_ESSENCE or
		itemType == ITEMTYPE_ENCHANTING_RUNE_POTENCY or
		itemType == ITEMTYPE_FLAVORING or
		itemType == ITEMTYPE_INGREDIENT or
		itemType == ITEMTYPE_LOCKPICK or
		itemType == ITEMTYPE_LURE or
		itemType == ITEMTYPE_POISON_BASE or
		itemType == ITEMTYPE_POTION_BASE or
		itemType == ITEMTYPE_RAW_MATERIAL or
		itemType == ITEMTYPE_REAGENT or
		itemType == ITEMTYPE_RECIPE or
		itemType == ITEMTYPE_SPICE or
		itemType == ITEMTYPE_STYLE_MATERIAL or
		itemType == ITEMTYPE_WEAPON_TRAIT or
		itemType == ITEMTYPE_WOODWORKING_BOOSTER or
		itemType == ITEMTYPE_WOODWORKING_MATERIAL or
		itemType == ITEMTYPE_WOODWORKING_RAW_MATERIAL or
		itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then
		itemLink = IIfA:GetItemID(itemLink)
	end

	local item = IIfA.database[itemLink]

	if ((queryItem.link ~= nil) and (item ~= nil)) then
		for locationName, location in pairs(item.locations) do
			AlreadySavedLoc = false
			if location.bagID == BAG_WORN or location.bagID == BAG_BACKPACK then
				locationName = IIfA.CharIdToName[locationName]
			end
			if locationName ~= nil then
				
				for x, QILocation in pairs(queryItem.locations) do
					if (QILocation.name == locationName)then
						QILocation.itemsFound = QILocation.itemsFound + location.itemCount
						AlreadySavedLoc = true
					end
				end
				
				if nil ~= location.itemCount then
					if (not AlreadySavedLoc) and (location.itemCount > 0) then
						newLocation = {}
						newLocation.name = locationName
						
						if locationName == location.bagID then -- location is a collectible
							newLocation.name = GetCollectibleNickname(locationName)
							if newLocation.name == "" then newLocation.name = GetCollectibleName(locationName) end
						end
						
						newLocation.itemsFound = location.itemCount
						newLocation.worn = location.bagID == BAG_WORN
						
						table.insert(queryItem.locations, newLocation)
					end
				end
			end
		end
	end
	return queryItem
end

function IIfA:SetSceneVisible(name, value)
	IIfA:GetSettings().frameSettings[name].hidden = not value
end

function IIfA:GetSceneVisible(name)
	if IIfA:GetSettings().frameSettings then
		return (not IIfA:GetSettings().frameSettings[name].hidden)
	else
		return true
	end
end



function IIfA:SetupBackpack()

	local function createInventoryDropdown()
		local comboBox, i

		if IIFA_GUI_Header_Dropdown.comboBox ~= nil then
			comboBox = IIFA_GUI_Header_Dropdown.comboBox
		else
			comboBox = ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown)
			IIFA_GUI_Header_Dropdown.comboBox = comboBox
		end

		function OnItemSelect(_, choiceText, choice)
	--		d("OnItemSelect", choiceText, choice)
			IIfA:SetInventoryListFilter(choiceText)
			PlaySound(SOUNDS.POSITIVE_CLICK)
		end

		comboBox:SetSortsItems(false)

		local validChoices =  IIfA:GetAccountInventoryList()

		for i = 1, #validChoices do
			entry = comboBox:CreateItemEntry(validChoices[i], OnItemSelect)
			comboBox:AddItem(entry)
			if validChoices[i] == IIfA:GetInventoryListFilter() then
				comboBox:SetSelectedItem(validChoices[i])
			end
		end

		return IIFA_GUI_Header_Dropdown
	end

	local function createInventoryDropdownQuality()
		local comboBox, i

		IIFA_GUI_Header_Dropdown_Quality.comboBox = IIFA_GUI_Header_Dropdown_Quality.comboBox or ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown_Quality)

		local validChoices =  {}
		table.insert(validChoices, "Any")
		table.insert(validChoices, getColoredString(ITEM_QUALITY_TRASH, "Junk"))
		table.insert(validChoices, getColoredString(ITEM_QUALITY_NORMAL, "Normal"))
		table.insert(validChoices, getColoredString(ITEM_QUALITY_MAGIC, "Magic"))
		table.insert(validChoices, getColoredString(ITEM_QUALITY_ARCANE, "Arcane"))
		table.insert(validChoices, getColoredString(ITEM_QUALITY_ARTIFACT, "Artifact"))
		table.insert(validChoices, getColoredString(ITEM_QUALITY_LEGENDARY, "Legendary"))

		local comboBox = IIFA_GUI_Header_Dropdown_Quality.comboBox	

		function OnItemSelect(_, choiceText, choice)
			IIfA:SetInventoryListFilterQuality(getQualityDict()[choiceText])
			PlaySound(SOUNDS.POSITIVE_CLICK)
		end

		comboBox:SetSortsItems(false)

		for i = 1, #validChoices do
			entry = comboBox:CreateItemEntry(validChoices[i], OnItemSelect)		
			comboBox:AddItem(entry)
			if getQualityDict()[validChoices[i]] == IIfA:GetInventoryListFilterQuality() then
				comboBox:SetSelectedItem(validChoices[i])
			end
		end

		return IIFA_GUI_Header_Dropdown
	end

	IIfA.InventoryListFilter = IIfA.data.in2DefaultInventoryFrameView
	IIfA:CreateInventoryScroll()
	createInventoryDropdown()
	createInventoryDropdownQuality()	
	IIfA:GuiOnSort(true)
end

function IIfA:ProcessRightClick(control)
	if control == nil then return end

	control = control:GetParent()
	if control:GetName():match("IIFA_ListItem") == nil or control.itemLink == nil then return end

	-- it's an IIFA list item, lets see if it has data, and allow menu if it does

	if control.itemLink ~= "" then
		zo_callLater(function()
			AddCustomMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() IIfA:GUIDoubleClick(control, MOUSE_BUTTON_INDEX_LEFT) end, MENU_ADD_OPTION_LABEL)
			AddCustomMenuItem("Missing Motifs to text", function() IIfA:FMC(control, "Private") end, MENU_ADD_OPTION_LABEL)
			AddCustomMenuItem("Missing Motifs to Chat", function() IIfA:FMC(control, "Public") end, MENU_ADD_OPTION_LABEL)
			AddCustomMenuItem("Filter by Item Name", function() IIfA:FilterByItemName(control) end, MENU_ADD_OPTION_LABEL)
			AddCustomMenuItem("Filter by Item Set Name", function() IIfA:FilterByItemSet(control) end, MENU_ADD_OPTION_LABEL)
			ShowMenu(control)
			end, 50
			)
	end
end


-- paste missing motif chapters to chat based on currently displayed list of items
function IIfA:FMC(control, WhoSeesIt)
--[[
-- next block taken from AI Research Grid
-- not helpful in that it gives back singular versions of everything, and breastplate instead of chest
-- Display Order in tooltip
	local styleChaptersLookup =
		{
		[1] = ITEM_STYLE_CHAPTER_AXES,
		[2] = ITEM_STYLE_CHAPTER_BELTS,
		[3] = ITEM_STYLE_CHAPTER_BOOTS,
		[4] = ITEM_STYLE_CHAPTER_BOWS,
		[5] = ITEM_STYLE_CHAPTER_CHESTS,
		[6] = ITEM_STYLE_CHAPTER_DAGGERS,
		[7] = ITEM_STYLE_CHAPTER_GLOVES,
		[8] = ITEM_STYLE_CHAPTER_HELMETS,
		[9] = ITEM_STYLE_CHAPTER_LEGS,
		[10] = ITEM_STYLE_CHAPTER_MACES,
		[11] = ITEM_STYLE_CHAPTER_SHIELDS,
		[12] = ITEM_STYLE_CHAPTER_SHOULDERS,
		[13] = ITEM_STYLE_CHAPTER_STAVES,
		[14] = ITEM_STYLE_CHAPTER_SWORDS,
		}
--]]

-- following lookup turns a motif number "Crafting Motif 33: Thieves Guild Axes" into an achieve lookup
-- |H1:achievement:1318:16383:1431113493|h|h
	local motifAchieves =
		{
		[15] = 1144,	-- Dwemer
		[16] = 1319, 	-- Glass
		[17] = 1181,	-- Xivkyn
		[18] = 1318,	-- Akaviri
		[19] = 1348,	-- Mercenary
		[20] = 1713,	-- Yokudan
		[21] = 1341,	-- Ancient Orc
		[22] = 1411,	-- Trinimac
		[23] = 1412,	-- Malacath
		[24] = 1417,	-- Outlaw
		[25] = 1415,	-- Aldmeri Dominion
		[26] = 1416,	-- Daggerfall Covenant
		[27] = 1414,	-- Ebonheart Pact
		[28] = 1797,	-- Ra Gada
--		[29] = 0,		-- Soul-Shriven
		[30] = 1933,	-- Morag Tong
		[31] = 1676, 	-- Skinchanger
		[32] = 1422, 	-- Abah's Watch
		[33] = 1423,	-- Thieves Guild
		[34] = 1424,	-- Assasins League
		[35] = 1659,	-- Dro-m'Athra
		[36] = 1661,	-- Dark Brotherhood
		[37] = 1798,	-- Ebony
		[38] = 1715,	-- Draugr
		[39] = 1662,	-- Minotaur
		[40] = 1660,	-- Order Hour
		[41] = 1714,	-- Celestial
		[42] = 1545,	-- Hollowjack
--		[43] = 0,		-- Harlequin
		[44] = 1796,	-- Silken Ring
		[45] = 1795,	-- Mazzatun
--		[46] = 0,		-- Stahlrim
		[47] = 1934,	-- Bouyant Armiger
		[48] = 1932,	-- Ashlander
		[49] = 1935,	-- Militant Ordinator
		[50] = 2023,	-- Telvani
		[51] = 2021,	-- Hlaalu
		[52] = 2022,	-- Redoran
		[54] = 2098,	-- Bloodforge
		[55] = 2097,	-- Dreadhorn
		[56] = 2044,	-- Apostle
		[57] = 2045,	-- Ebonshadow
		}

--		local i, a
--		for i,a in pairs(motifAchieves) do
--			d(i .. " = |H1:achievement:" .. a .. ":16383:1431113493|h|h")
--		end

	local langChapNames = {}
	langChapNames["EN"] = {"Axes", "Belts", "Boots", "Bows", "Chests", "Daggers", "Gloves", "Helmets", "Legs", "Maces", "Shields", "Shoulders", "Staves", "Swords" }
	langChapNames["DE"] = {"Äxte", "Gürtel", "Stiefel", "Bogen", "Torsi", "Dolche", "Handschuhe", "Helme", "Beine", "Keulen", "Schilde", "Schultern", "Stäbe", "Schwerter" }
	local chapnames = langChapNames[GetCVar("language.2")] or langChapNames["EN"]

	if control.itemLink == nil or control.itemLink == "" then
		d("Invalid item. Right-Click ignored.")
		return
	end

	local motifNum
	motifNum = GetItemLinkName(control.itemLink):match("%d+")
	motifNum = tonumber(motifNum)
	if motifAchieves[motifNum] == nil then
		d(control.itemLink .. " is not a valid motif chapter")
		return
	end

--	local chapnames = {}, idx, chapType
--	for idx, chapType in pairs(styleChaptersLookup) do
--		chapnames[idx - 1] = GetString("SI_ITEMSTYLECHAPTER", chapType)
--	end

	local idx, data, i, val
	local chapVal
	chapVal = 0
	for idx, data in pairs(IIFA_GUI_ListHolder.dataLines) do
		for i, val in pairs(chapnames) do
			if chapnames[i] ~= nil then
				if zo_plainstrfind(data.name, val) and zo_plainstrfind(data.name, tostring(motifNum)) then
					chapnames[i] = nil
					chapVal = chapVal + (2 ^ (i - 1))
				end
			end
		end
	end

	local s = ""
	for i, val in pairs(chapnames) do
		if val ~= nil then
			if s == "" then
				s = val
			else
				s = string.format("%s, %s", s, val)
			end
		end
	end

	if s == "" then
		d("No motif chapters missing")
	else
		-- incomplete motif achieve
		-- |H1:achievement:1416:0:0|h|h
		local motifStr = string.format("|H1:achievement:%s:%s:0|h|h", motifAchieves[motifNum], chapVal)

		if WhoSeesIt == "Private" then
			d("Missing " .. motifStr .. " chapters: " .. s)
		end

		if WhoSeesIt == "Public" then
			d("Missing motif chapters are in the chat text edit area")
			ZO_ChatWindowTextEntryEditBox:SetText("Looking for " .. motifStr .. " missing chapters: " .. s)
		end

	end
	--d(chapnames)

end

function IIfA:FilterByItemName(control)

	local itemName
	itemName = GetItemLinkName(control.itemLink)

	IIfA.searchFilter = itemName
	-- IIFA_GUI_SetNameOnly_Checked:SetHidden(true)
	IIFA_GUI_SearchBox:SetText(itemName)
	IIFA_GUI_SearchBoxText:SetHidden(true)
	IIfA.bFilterOnSetName = false
    IIfA:UpdateScrollDataLinesData()
    IIfA:UpdateInventoryScroll()

end

function IIfA:FilterByItemSet(control)

	local itemLink
	itemLink = control.itemLink
	if itemLink == nil then
		return
	end
	local hasSetInfo, setName
	hasSetInfo, setName = GetItemLinkSetInfo(itemLink, false)
	if hasSetInfo then
		IIfA.searchFilter = setName
		-- fill in the GUI portion here
	else
		d("Item is not part of a set. Filter not changed.")
		return
	end

	IIfA.searchFilter = setName
	-- IIFA_GUI_SetNameOnly_Checked:SetHidden(false)
	IIFA_GUI_SearchBox:SetText(setName)
	IIFA_GUI_SearchBoxText:SetHidden(true)
	IIfA.bFilterOnSetName = true
    IIfA:UpdateScrollDataLinesData()
    IIfA:UpdateInventoryScroll()

end



--[[
misc musings

--|H1:item:45350:365:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h

ww writ
ruby ash healing staff, epic, nirnhoned, magnus gift set, glass, 48 writ voucher reward
/script local i for i=1,100 do d(i .. " = " .. GenerateMasterWritBaseText("|H1:item:119681:6:1:0:0:0:" .. i .. ":192:4:48:26:28:0:0:0:0:0:0:0:0:480000|h|h")) end

maple resto staff
|H1:item:43560:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0:0|h|h

nobles conquest robe
|H1:item:59965:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h
|H1:item:60000:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h
]]
