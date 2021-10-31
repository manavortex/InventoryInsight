local IIfA = IIfA

local _

IIfA.ScrollSortUp = true
IIfA.ActiveFilter = 0
IIfA.ActiveSubFilter = 0
IIfA.InventoryFilter = "All"

IIfA.InventoryListFilter = "Any"
IIfA.InventoryListFilterQuality = 99

local function p(...) IIfA:DebugOut(...) end
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

	IIfA:RefreshInventoryScroll()
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
	IIfA:RefreshInventoryScroll()
end



--[[----------------------------------------------------------------------]]
--[[----------------------------------------------------------------------]]
--[[------ GUI functions  ------------------------------------------------]]

function IIfA:GUIDoubleClick(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT and control.itemLink then
		if control.itemLink ~= IIfA.EMPTY_STRING then
			ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. zo_strformat(SI_TOOLTIP_ITEM_NAME, control.itemLink))
		end
	end
end

local function getHouseIds()
	local ret = {}
	for houseName, houseId in pairs(IIfA:GetTrackedHouses()) do
		table.insert(ret, houseId)
	end
	return ret
end

local function isHouse()
	return IIfA:GetTrackingWithHouseNames()[locationName]
end

function IIfA:IsOneOf(value, comp1, comp2, comp3, comp4, comp5, comp6)
	return nil ~= value and (value == comp6) or (value == comp5) or (value == comp4) or (value == comp3) or (value == comp2) or value == comp1
end

local function DoesInventoryMatchList(locationName, location)
	local bagId 	= location.bagID
	local filter 	= IIfA.InventoryListFilter
	local filterBag = IIfA.InventoryListFilterBagId

--	if locationName == "attributes" then return false end
	if (filter == "All") then
		return true

	elseif (filter == "All Banks") then
		return IIfA:IsOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_GUILDBANK) and IIfA.trackedBags[bagId]

	elseif (filter == "All Guild Banks") then
		return IIfA:IsOneOf(bagId, BAG_GUILDBANK)

	elseif (filter == "All Characters") then
		return IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN)

	elseif (filter == "All Storage") then
		return IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_VIRTUAL) or
			GetCollectibleForHouseBankBag(bagId) > 0

	elseif (filter == "Everything I own") then
		return IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_VIRTUAL) or
			GetCollectibleForHouseBankBag(bagId) > 0 or
			IIfA.data.collectHouseData[bagId]

	elseif (filter == "Bank and Characters") then
		return IIfA:IsOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_BACKPACK, BAG_WORN)

	elseif(filter == "Bank and Current Character") then
		return IIfA:IsOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK) or
			(IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN) and locationName == IIfA.currentCharacterId)

	elseif(filter == "Bank and other characters") then
		return IIfA:IsOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK) or
			(IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN) and locationName ~= IIfA.currentCharacterId)

	elseif(filter == "Bank Only") then
		return IIfA:IsOneOf(bagId, BAG_BANK, BAG_SUBSCRIBER_BANK)

	elseif(filter == "Craft Bag") then
		return (bagId == BAG_VIRTUAL)

	elseif(filter == "Housing Storage" and filterBag == nil) then	-- all housing storage chests/coffers
		return GetCollectibleForHouseBankBag(bagId) > 0

	elseif(filter == "Housing Storage" and filterBag ~= nil) then	-- specific housing storage chest/coffer
		return bagId == filterBag and GetCollectibleForHouseBankBag(bagId) > 0

	elseif(filter == "All Houses") then
		return IIfA.data.collectHouseData[bagId] or false

	elseif(nil ~= IIfA:GetHouseIdFromName(filter)) then
		return (bagId == IIfA:GetHouseIdFromName(filter))

	else --Not a preset, must be a specific guildbank or character
		if IIfA:IsOneOf(bagId, BAG_BACKPACK, BAG_WORN) then
			-- it's a character name, convert to Id, check that against location Name in the dbv3 table
			if locationName == IIfA.CharNameToId[filter] then return true end
		else
			-- it's a bank to compare, do it direct
			return locationName == filter
		end
	end
end

--@Baertram:
--Made the function global to be used in other addons like FCOItemSaver
function IIfA:DoesInventoryMatchList(locationName, location)
	return DoesInventoryMatchList(locationName, location)
end

local function matchCurrentInventory(locationName)
--	if locationName == "attributes" then return false end
	local accountInventoryList = IIfA:GetAccountInventoryList()

	for i, inventoryName in pairs(accountInventoryList) do
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
		qualityDictionary =
		{
			["Any"] = 99,
			[getColoredString(ITEM_DISPLAY_QUALITY_TRASH, "Junk")] = ITEM_DISPLAY_QUALITY_TRASH,
			[getColoredString(ITEM_DISPLAY_QUALITY_NORMAL, "Normal")] = ITEM_DISPLAY_QUALITY_NORMAL,
			[getColoredString(ITEM_DISPLAY_QUALITY_MAGIC, "Magic")] = ITEM_DISPLAY_QUALITY_MAGIC,
			[getColoredString(ITEM_DISPLAY_QUALITY_ARCANE, "Arcane")] = ITEM_DISPLAY_QUALITY_ARCANE,
			[getColoredString(ITEM_DISPLAY_QUALITY_ARTIFACT, "Artifact")] = ITEM_DISPLAY_QUALITY_ARTIFACT,
			[getColoredString(ITEM_DISPLAY_QUALITY_LEGENDARY, "Legendary")] = ITEM_DISPLAY_QUALITY_LEGENDARY,
			[getColoredString(ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE, "Mythic")] = ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE,
		}
	end
	return qualityDictionary
end

function IIfA:getQualityDict()
	return qualityDictionary or getQualityDict()
end

local function matchFilter(itemName, itemLink)
	local ret = true
	local retSet = false
	local itemMatch = false
	local hasSetInfo, setName
	local name

	local searchFilter = IIfA.searchFilter
	-- 17-7-30 AM - moved lowercasing to when it's created, one less call to lowercase for every item

	--Empty search string? Then skip all searches with names
	if searchFilter and searchFilter > IIfA.EMPTY_STRING then
		if itemName > IIfA.EMPTY_STRING then
			name = tostring(ZO_CachedStrFormat("<<C:1>>", itemName))
			name = name:lower()
		end
--d(">IIfa:matchFilter - name: " ..tostring(name) .. ", searchFilter: " ..tostring(searchFilter))
		-- text filter takes precedence
		-- 3-6-17 AM - you're either filtering on a set name, or not - much less confusing (hopefully)
		local bFilterOnSetNameToo = IIfA:GetSettings().bFilterOnSetNameToo
		if IIfA.bFilterOnSetName or bFilterOnSetNameToo then
			hasSetInfo, setName = IIfA:IsItemSet(itemLink)
			if hasSetInfo then
				retSet = zo_plainstrfind(setName:lower(), searchFilter)
			end
		end
		-- Only compare set: No point in going any further, this item doesn't have set info at all, so return a fail and keep truckin
		if IIfA.bFilterOnSetName and (not hasSetInfo or not retSet) then return false end
		--Name comparison (without sets)
		if not IIfA.bFilterOnSetName and name and name > IIfA.EMPTY_STRING then
			ret = retSet or zo_plainstrfind(name, searchFilter)
		end
	end

	local bWorn = false
	local equipType = 0
	local itemType = 0
--	local itemQuality = ITEM_QUALITY_NORMAL
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
				if itemType == WEAPONTYPE_SHIELD and IIfA.filterTypes == nil then		-- all weaps is selected, don't show shields in list
					itemType = 0
				end
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

	local sort1 = (IIfA.bSortQuality and a.quality) or a.name
	local sort2 = (IIfA.bSortQuality and b.quality) or b.name
	return (sort1 or IIfA.EMPTY_STRING) < (sort2 or IIfA.EMPTY_STRING)
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

local function itemSum(location)
	if type(location.bagSlot) ~= "table" then return 0 end
	local totQty = 0
	local bagSlot, itemCount
	for bagSlot, itemCount in pairs(location.bagSlot) do
		totQty = totQty + itemCount
	end
	return totQty
end

local function checkSearchFilter(searchFilterNew)
	local searchFilterCurrent = IIfA.searchFilter
	if ((searchFilterNew and searchFilterCurrent and searchFilterNew ~= searchFilterCurrent) or
		(not searchFilterNew and not searchFilterCurrent) or
		(searchFilterCurrent and searchFilterCurrent == "Click to search..."))
	then
		searchFilterNew = searchFilterNew or IIfA.GUI_SearchBox:GetText()
		searchFilterNew = ZO_CachedStrFormat("<<C:1>>", searchFilterNew)
		return zo_strlower(searchFilterNew)
	else
		return searchFilterCurrent
	end
end

-- fill the shown item list with items that match current filter(s)
function IIfA:UpdateScrollDataLinesData()
	IIfA.searchFilter = checkSearchFilter()
--d("IIfA:UpdateScrollDataLinesData - IIfA.searchFilter: " ..tostring(IIfA.searchFilter))
	--local index = 0
	local dataLines = {}
	local DBv3 = IIfA.database
	local itemLink, itemKey, iconFile, itemQuality, tempDataLine = nil
	local itemTypeFilter
	local itemCount
	local match = false
	local bWorn = false
	local dbItem
	local totItems = 0

	if(DBv3)then
		for itemKey, dbItem in pairs(DBv3) do
			if zo_strlen(itemKey) < 10 then
				itemLink = dbItem.itemLink
			else
				itemLink = itemKey
			end

			if (itemKey ~= IIfA.EMPTY_STRING) then

				itemTypeFilter = 0
				if (dbItem.filterType) then
					itemTypeFilter = dbItem.filterType
				end

				itemCount = 0
				bWorn = false
				local itemIcon = GetItemLinkIcon(itemLink)

				local locationName, locData
				local itemCount = 0
				for locationName, locData in pairs(dbItem.locations) do
					itemCount = itemCount + itemSum(locData)
					if DoesInventoryMatchList(locationName, locData) then
						match = true
					end
					bWorn = bWorn or (locData.bagID == BAG_WORN)
				end
				local itemName = dbItem.itemName
				if not itemName or #itemName == 0 then
					p("Filling in missing itemName/Quality")
					itemName = GetItemLinkName(itemLink)
					dbItem.itemName = itemName
					dbItem.itemQuality = GetItemLinkQuality(itemLink)
				end
				tempDataLine = {
					link = itemLink,
					qty = itemCount,
					icon = itemIcon,
					name = itemName,
					quality = dbItem.itemQuality,
					filter = itemTypeFilter,
					worn = bWorn
				}

				if(itemCount > 0) and matchFilter(itemName, itemLink) and matchQuality(dbItem.itemQuality) and match then
					table.insert(dataLines, tempDataLine)
					totItems = totItems + (itemCount or 0)
				end
				match = false
			end
		end
	end

	IIFA_GUI_ListHolder.dataLines = dataLines
	sort(IIFA_GUI_ListHolder.dataLines)
	IIFA_GUI_ListHolder.dataOffset = 0
	IIFA_GUI_ListHolder_Slider:SetValue(0)

	-- even if the counts aren't visible, update them so they show properly if user turns them on
	IIFA_GUI_ListHolder_Counts_Items:SetText("Item count: " .. totItems)
	IIFA_GUI_ListHolder_Counts_Slots:SetText("Appx. slots used: " .. #dataLines)

end

--Update the FCOItemSaver marker icons at the IIfA inventory frames
local function updateFCOISMarkerIcons(curLine, showFCOISMarkerIcons, createFCOISMarkerIcons, iconId)
	if not FCOIS or not IIfA.UpdateFCOISMarkerIcons then return end
	IIfA:UpdateFCOISMarkerIcons(curLine, showFCOISMarkerIcons, createFCOISMarkerIcons, iconId)
end

local function fillLine(curLine, curItem)
	local color
	if curItem == nil then
		curLine.itemLink = IIfA.EMPTY_STRING
		curLine.icon:SetTexture(nil)
		curLine.icon:SetAlpha(0)
		curLine.text:SetText(IIfA.EMPTY_STRING)
		curLine.qty:SetText(IIfA.EMPTY_STRING)
		curLine.worn:SetHidden(true)
		curLine.stolen:SetHidden(true)
		--Hide the FCOIS marker icons at the line (do not create them if not needed) -> File plugins/FCOIS/IIfA_FCOIS.lua
		updateFCOISMarkerIcons(curLine, false, false, -1)
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
		--Show the FCOIS marker icons at the line, if enabled in the settings (create them if needed)  -> File plugins/FCOIS/IIfA_FCOIS.lua
		updateFCOISMarkerIcons(curLine, IIfA:GetSettings().FCOISshowMarkerIcons, false, -1)
	end
end

function IIfA:SetDataLinesData()
--	p("SetDataLinesData")

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

	------------------------------------------------------
	if IIFA_GUI_ListHolder.dataOffset < 0 then IIFA_GUI_ListHolder.dataOffset = 0 end
	if IIFA_GUI_ListHolder.maxLines == nil then
		IIFA_GUI_ListHolder.maxLines = 35
	end
	IIfA:SetDataLinesData()

	local total = #IIFA_GUI_ListHolder.dataLines - IIFA_GUI_ListHolder.maxLines
	IIFA_GUI_ListHolder_Slider:SetMinMax(0, total)
end

function IIfA:RefreshInventoryScroll()

	-- p("RefreshInventoryScroll")

	IIfA:UpdateScrollDataLinesData()
	IIfA:UpdateInventoryScroll()
end

function IIfA:SetItemCountPosition()
	for i=1, IIFA_GUI_ListHolder.maxLines do
		local line = IIFA_GUI_ListHolder.lines[i]
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
	p("CreateInventoryScroll")

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
	local charList = {}
	for i=1, GetNumCharacters() do
		local charName = GetCharacterInfo(i)
		charName = charName:sub(1, charName:find("%^") - 1)
		if (nil == charList[charName]) then
			table.insert(charList, charName)
		end
	end
	return charList
end

function IIfA:GetAccountInventoryList()
	local accountInventories = IIfA.dropdownLocNames

-- get character names, will present in same order as character selection screen
	for idx, charName in ipairs(IIfA:GetCharacterList()) do
		if (nil == accountInventories[charName]) then
			table.insert(accountInventories, charName)
		end
	end

-- banks are same as toons, same order as player normally sees them
	if IIfA.data.bCollectGuildBankData then
		for i = 1, GetNumGuilds() do
			local id = GetGuildId(i)
			local guildName = GetGuildName(id)

			-- on the off chance that this doesn't exist already, create it
			if IIfA.guildBanks == nil then
				IIfA.guildBanks = {}
			end

			if IIfA.guildBanks[guildName] ~= nil then
				table.insert(accountInventories, guildName)
			end
		end
	end

	-- house item inventories
	if IIfA.data.b_collectHouses then
		-- table.insert(accountInventories, "All Houses") --  4-11-18 AM - removed duplicate entry, it's in the dropdownLocNames already
		for idx, houseName in pairs(IIfA:GetTrackedHouseNames()) do
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
	local itemCount = 0

	itemLink = IIfA:GetItemKey(itemLink)

	local item = IIfA.database[itemLink]

	if ((queryItem.link ~= nil) and (item ~= nil)) then
		for locationName, location in pairs(item.locations) do
			itemCount = itemSum(location)
			AlreadySavedLoc = false
			if location.bagID == BAG_WORN or location.bagID == BAG_BACKPACK then
				locationName = IIfA.CharIdToName[locationName]
			end
			if locationName ~= nil then
				for x, QILocation in pairs(queryItem.locations) do
					if (QILocation.name == locationName)then
						QILocation.itemsFound = QILocation.itemsFound + itemCount
						AlreadySavedLoc = true
					end
				end

				if itemCount ~= nil and itemCount > 0 then
					if (not AlreadySavedLoc) and (itemCount > 0) then
						newLocation = {}
						newLocation.name = locationName

						if location.bagID == BAG_WORN or location.bagID == BAG_BACKPACK then
							newLocation.bagLoc = BAG_BACKPACK
						elseif location.bagID == BAG_BANK or location.bagID == BAG_SUBSCRIBER_BANK then
							newLocation.bagLoc = BAG_BANK
						elseif location.bagID == BAG_VIRTUAL then
							newLocation.bagLoc = BAG_VIRTUAL
						elseif location.bagID == BAG_GUILDBANK then
							newLocation.bagLoc = BAG_GUILDBANK
						elseif location.bagID >= BAG_HOUSE_BANK_ONE and location.bagID <= BAG_HOUSE_BANK_TEN then -- location is a housing chest
							newLocation.name = GetCollectibleNickname(locationName * 1)
							if newLocation.name == IIfA.EMPTY_STRING then newLocation.name = GetCollectibleName(locationName) end
							newLocation.bagLoc = BAG_HOUSE_BANK_ONE
						elseif location.bagID == locationName then	-- location is a house
							newLocation.name = GetCollectibleName(locationName * 1)
							newLocation.bagLoc = 99
						end

						newLocation.itemsFound = itemCount
						newLocation.worn = location.bagID == BAG_WORN

						table.insert(queryItem.locations, newLocation)
					end
				end
			end
		end
	end
	return queryItem
end

-- test query
-- /script d(IIfA:QueryAccountInventory("|H0:item:134629:6:1:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:0:0|h|h"))

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

-- general note for popup menus
-- example here http://www.esoui.com/downloads/info1146-LibCustomMenu.html
-- AddCustomSubMenuItem(mytext, entries, myfont, normalColor, highlightColor, itemYPad)

function IIfA:SetupBackpack()

	local function createInventoryDropdown()
		local comboBox, i, entry

		if IIFA_GUI_Header_Dropdown_Main.comboBox ~= nil then
			comboBox = IIFA_GUI_Header_Dropdown_Main.comboBox
		else
			comboBox = ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown_Main)
			IIFA_GUI_Header_Dropdown_Main.comboBox = comboBox
		end

		local function OnItemSelect(_, choiceText, choice)
	--		d("OnItemSelect", choiceText, choice)
			IIfA:SetInventoryListFilter(choiceText)
			IIfA:RefreshInventoryScroll()
			PlaySound(SOUNDS.POSITIVE_CLICK)
		end

		local function OnChestSelect(_, choiceText, choice)
-- p("OnChestSelect '<<1>>' - <<2>>", choiceText, choice)
			local ctr, cName, cId
			for ctr = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
				cId = GetCollectibleForHouseBankBag(ctr)
				cName = GetCollectibleNickname(cId)
				if cName == self.EMPTY_STRING then
					cName = GetCollectibleName(cId)
				end
				--remove gender specific characters from house bank chest name
				cName = zo_strformat("<<C:1>>", cName)
				if cName == choiceText then
					IIfA:SetInventoryListFilter("Housing Storage", ctr)
					break
				end
			end
			IIfA:RefreshInventoryScroll()
			PlaySound(SOUNDS.POSITIVE_CLICK)
		end

		comboBox:SetSortsItems(false)

		IIFA_GUI_Header_Dropdown_Main.m_comboBox.m_height = 500		-- normal height is 250, so just double it (will be plenty tall for most users - even Mana)

		local validChoices =  IIfA:GetAccountInventoryList()

		for i = 1, #validChoices do
			entry = comboBox:CreateItemEntry(validChoices[i], OnItemSelect)
			d(comboBox:AddItem(entry))
			if validChoices[i] == IIfA:GetInventoryListFilter() then
				comboBox:SetSelectedItem(validChoices[i])
			end
		end

		local ctr, cName, cId
		for ctr = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
			cId = GetCollectibleForHouseBankBag(ctr)
			if IsCollectibleUnlocked(cId) then
				cName = GetCollectibleNickname(cId)
				if cName == self.EMPTY_STRING then
					cName = GetCollectibleName(cId)
				end
				--remove gender specific characters from house bank chest name
				cName = zo_strformat("<<C:1>>", cName)
				entry = comboBox:CreateItemEntry(cName, OnChestSelect)
				comboBox:AddItem(entry)
			end
		end

		local function ScrollableMenuItemPrehookMouseEnter(control)
			if control:GetName():find("IIFA_GUI_Header_Dropdown_Main") ~= nil then
				local itemLabel = control:GetNamedChild("Label"):GetText()
				if IIfA.dropdownLocNamesTT[itemLabel] then
					IIfA:GuiShowTooltip(control, IIfA.dropdownLocNamesTT[itemLabel])
				end
			end
		end
		local function ScrollableMenuItemPrehookMouseExit(control)
			IIfA:GuiHideTooltip(control)
		end

		ZO_PreHook("ZO_ScrollableComboBox_Entry_OnMouseEnter", ScrollableMenuItemPrehookMouseEnter)
		ZO_PreHook("ZO_ScrollableComboBox_Entry_OnMouseExit", ScrollableMenuItemPrehookMouseExit)
	end

	local function createInventoryDropdownQuality()
		local comboBox, i
		local qualityDict = getQualityDict()

		IIFA_GUI_Header_Dropdown_Quality.comboBox = IIFA_GUI_Header_Dropdown_Quality.comboBox or ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_Dropdown_Quality)

		local validChoices =
		{
			"Any",
			getColoredString(ITEM_DISPLAY_QUALITY_TRASH, "Junk"),
			getColoredString(ITEM_DISPLAY_QUALITY_NORMAL, "Normal"),
			getColoredString(ITEM_DISPLAY_QUALITY_MAGIC, "Magic"),
			getColoredString(ITEM_DISPLAY_QUALITY_ARCANE, "Arcane"),
			getColoredString(ITEM_DISPLAY_QUALITY_ARTIFACT, "Artifact"),
			getColoredString(ITEM_DISPLAY_QUALITY_LEGENDARY, "Legendary"),
			getColoredString(ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE, "Mythic"),
		}

		local comboBox = IIFA_GUI_Header_Dropdown_Quality.comboBox

		local function OnItemSelect(_, choiceText, choice)
			IIfA:SetInventoryListFilterQuality(getQualityDict()[choiceText])
			PlaySound(SOUNDS.POSITIVE_CLICK)
		end

		comboBox:SetSortsItems(false)

		for i = 1, #validChoices do
			local entry = comboBox:CreateItemEntry(validChoices[i], OnItemSelect)
			comboBox:AddItem(entry)
			if qualityDict[validChoices[i]] == IIfA:GetInventoryListFilterQuality() then
				comboBox:SetSelectedItem(validChoices[i])
			end
		end
		-- return IIFA_GUI_Header_Dropdown
	end

	IIfA.InventoryListFilter = IIfA.data.in2DefaultInventoryFrameView
	IIfA:CreateInventoryScroll()
	createInventoryDropdown()
	createInventoryDropdownQuality()

	-- IIfA:GuiOnSort()
end

function IIfA:ProcessRightClick(control)
	if control == nil then return end

	control = control:GetParent()
	if control:GetName():match("IIFA_ListItem") == nil or control.itemLink == nil then return end

	-- it's an IIFA list item, lets see if it has data, and allow menu if it does
	local itemLink = control.itemLink
	if itemLink and itemLink ~= IIfA.EMPTY_STRING then
		zo_callLater(function()
			AddCustomMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() IIfA:GUIDoubleClick(control, MOUSE_BUTTON_INDEX_LEFT) end, MENU_ADD_OPTION_LABEL)
			--Check if the item is a motif
			local isMotif, motifNum = IIfA:IsItemMotif(itemLink)
			if isMotif and motifNum then
				AddCustomMenuItem("Missing motifs (#"..tostring(motifNum) ..") to text", function() IIfA:FMC(control, "Private") end, MENU_ADD_OPTION_LABEL)
				AddCustomMenuItem("Missing motifs (#"..tostring(motifNum) ..") to chat", function() IIfA:FMC(control, "Public") end, MENU_ADD_OPTION_LABEL)
			end
			AddCustomMenuItem("Filter by Item Name", function() IIfA:FilterByItemName(control) end, MENU_ADD_OPTION_LABEL)
			--Check if the item is as set
			local isSet, setName = IIfA:IsItemSet(itemLink)
			if isSet then
				AddCustomMenuItem("Filter by Item Set Name", function() IIfA:FilterByItemSet(control, setName) end, MENU_ADD_OPTION_LABEL)
			end
			ShowMenu(control)
		end, 0)
	end
end


function IIfA:IsItemSet(itemLink)
	if itemLink == nil then return false, nil end
	local hasSetInfo, setName = GetItemLinkSetInfo(itemLink, false)
	hasSetInfo = hasSetInfo or false
	if setName and setName > IIfA.EMPTY_STRING then
		setName = ZO_CachedStrFormat("<<C:1>>", setName)
	end
	return hasSetInfo, setName
end

function IIfA:IsItemMotif(itemLink)
	local motifNum = GetItemLinkName(itemLink):match("%d+")
	motifNum = tonumber(motifNum)
	local motifAchieves = IIfA:GetMotifAchieves()
	if motifAchieves[motifNum] ~= nil then return true, motifNum end
	return false, nil
end

function IIfA:GetMotifAchieves()
-- following lookup turns a motif number "Crafting Motif 33: Thieves Guild Axes" into an achieve lookup
-- |H1:achievement:1318:16383:1431113493|h|h
-- the index is the # from the motif text, NOT any internal value
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
		[58] = 2190,	-- Fang Lair
		[59] = 2189,	-- Scalecaller
		[60] = 2120,	-- Worm Cult
		[61] = 2186, 	-- Psijic
		[62] = 2187,	-- Sapiarch
		[63] = 2188,	-- Dremora
		[64] = 2285,	-- Pyandonean
		[65] = 2317,	-- Huntsman
		[66] = 2318,	-- Silver Dawn
		[67] = 2319,	-- Welkynar
		[68] = 2359,	-- Honor Guard
		[69] = 2360,	-- Dead Water
		[70] = 2361,	-- Elder Argonian
		[71] = 2503,	-- Coldsnap
		[72] = 2504,	-- Meridian
		[73] = 2505,	-- Annequina            *
		[74] = 2506,	-- Pellitine            *
		[75] = 2507, 	-- Sunspire
		[76] = 2630,	-- Dragonguard
		[77] = 2629,	-- Stags of Z'en        *
		[78] = 2628,	-- Moongrave Fane
		}
	return motifAchieves
end


-- paste missing motif chapters to chat based on currently displayed list of items
function IIfA:FMC(control, WhoSeesIt)
--		local i, a
--		for i,a in pairs(motifAchieves) do
--			d(i .. " = |H1:achievement:" .. a .. ":16383:1431113493|h|h")
--		end
	local itemLink = control.itemLink
	local motifAchieves = IIfA:GetMotifAchieves()
	if not motifAchieves then return end

	local langChapNames = {}
	langChapNames["EN"] = {"Axes", "Belts", "Boots", "Bows", "Chests", "Daggers", "Gloves", "Helmets", "Legs", "Maces", "Shields", "Shoulders", "Staves", "Swords" }
	langChapNames["DE"] = {"Äxte", "Gürtel", "Stiefel", "Bogen", "Torsi", "Dolche", "Handschuhe", "Helme", "Beine", "Keulen", "Schilde", "Schultern", "Stäbe", "Schwerter" }
	local chapnames = langChapNames[IIfA.clientLanguage] or langChapNames["EN"]

	if itemLink == nil or itemLink == IIfA.EMPTY_STRING then
		d("Invalid item. Right-Click ignored.")
		return
	end

	local isMotif, motifNum = IIfA:IsMotif(itemLink)
	if not isMotif then
		d(itemLink .. " is not a valid motif chapter")
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

	local s = IIfA.EMPTY_STRING
	for i, val in pairs(chapnames) do
		if val ~= nil then
			if s == IIfA.EMPTY_STRING then
				s = val
			else
				s = string.format("%s, %s", s, val)
			end
		end
	end

	if s == IIfA.EMPTY_STRING then
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

	IIfA.searchFilter = checkSearchFilter(itemName)
	IIfA.GUI_SearchBox:SetText(IIfA.searchFilter)
	IIfA.GUI_SearchBoxText:SetHidden(true)
	IIfA.bFilterOnSetName = false
	IIfA:RefreshInventoryScroll()
end

function IIfA:FilterByItemSet(control, setName)
	if not setName and not control then return end
	if not setName and control then
		local isSet, setNameLoc = IIfA:IsItemSet(control.itemLink)
		if isSet then
			setName = setNameLoc
		end
	end
	if setName and setName > IIfA.EMPTY_STRING then
		IIfA.searchFilter = checkSearchFilter(setName)
		-- fill in the GUI portion here
		IIfA.GUI_SearchBox:SetText(IIfA.searchFilter)
		IIfA.GUI_SearchBoxText:SetHidden(true)
		IIfA.bFilterOnSetName = true
		IIfA:RefreshInventoryScroll()
	end
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
