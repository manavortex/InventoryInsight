local IIfA = IIfA
IIfA.houseNameToIdTbl = {}

local task 	= IIfA.task or LibAsync:Create("IIfA_DataCollection")
IIfA.task	= task

function IIfA:IsCharacterInventoryIgnored()
	return IIfA.data.ignoredCharInventories[IIfA.currentCharacterId] or false
end

function IIfA:IgnoreCharacterInventory(value)
	IIfA.data.ignoredCharInventories[IIfA.currentCharacterId] = value

	IIfA.trackedBags[BAG_BACKPACK] = not value
	if value then
		IIfA:ClearLocationData(IIfA.currentCharacterId, BAG_BACKPACK)
	else
		IIfA:ScanCurrentCharacter()
	end
	IIfA:RefreshInventoryScroll()
end

function IIfA:IsCharacterEquipIgnored()
	return IIfA.data.ignoredCharEquipment[IIfA.currentCharacterId] or false
end

function IIfA:IgnoreCharacterEquip(value)
	IIfA.data.ignoredCharEquipment[IIfA.currentCharacterId] = value

	IIfA.trackedBags[BAG_WORN] = not value
	if value then
		IIfA:ClearLocationData(IIfA.currentCharacterId, BAG_WORN)
	else
		IIfA:ScanCurrentCharacter()
	end
	IIfA:RefreshInventoryScroll()
end

function IIfA:GetIgnoredCharacterList()
	local ret = {}
	local wasAdded = {}
	for characterName, characterData in pairs(IIfA.data.ignoredCharEquipment) do
		table.insert(ret, characterName)
		wasAdded[characterName] = true
	end
	for characterName, characterData in pairs(IIfA.data.ignoredCharInventories) do
		if not wasAdded[characterName] then
			table.insert(ret, characterName)
		end
	end
	return ret
end

function IIfA:SetSetNameFilterOnly(value)
	IIfA.bFilterOnSetName = not IIfA.bFilterOnSetName
	IIFA_GUI_Search_SetNameOnly:SetState((IIfA.bFilterOnSetName and BSTATE_PRESSED) or BSTATE_NORMAL)
	IIfA:RefreshInventoryScroll()
end

function IIfA:GetFocusSearchOnToggle()
	return not IIfA.defaults.dontFocusSearch
end
function IIfA:SetFocusSearchOnToggle(value)
	IIfA.defaults.dontFocusSearch = not value
end


-- Get pointer to current settings based on user pref (global or per char)
function IIfA:GetSettings()
	if IIfA.data.saveSettingsGlobally then return IIfA.data end
	return IIfA.settings
end

-- this is for the dropdown menu
function IIfA:GetInventoryListFilter()
	if not IIfA.InventoryListFilter then return "All" end
	return IIfA.InventoryListFilter
end


function IIfA:SetInventoryListFilter(value, bagId)
	if not value or value == IIfA.EMPTY_STRING then value = "All" end
	IIfA.InventoryListFilter = value
	IIfA.InventoryListFilterBagId = bagId
--	IIfA.searchFilter = IIfA.GUI_SearchBox:GetText()
	IIfA:RefreshInventoryScroll()
end

-- this is for the dropdown menu
function IIfA:GetInventoryListFilterQuality()
	return IIfA.InventoryListFilterQuality or 99
end

-- this is for the dropdown menu
function IIfA:SetInventoryListFilterQuality(value)
	IIfA.InventoryListFilterQuality = value
--	IIfA.searchFilter = IIfA.GUI_SearchBox:GetText()
	IIfA:RefreshInventoryScroll()
end
function IIfA:GetCollectingHouseData()
	return IIfA.data.b_collectHouses
end

function IIfA:GetTrackedBags()
	return IIfA.trackedBags
end

function IIfA:GetTrackedHousIds()
	local ret = {}
	for id, trackIt in pairs(IIfA.data.collectHouseData) do
		if trackIt then
			table.insert(ret, id)
		end
	end
	return ret
end
function IIfA:GetIgnoredHouseIds()
	local ret = {}
	for id, trackIt in pairs(IIfA.data.collectHouseData) do
		if not trackIt then table.insert(ret, id) end
	end
	return ret
end

function IIfA:GetHouseIdFromName(houseName)
	return IIfA.houseNameToIdTbl[houseName]
end

function IIfA:GetTrackingWithHouseNames()
	local ret = {}
	for collectibleId, trackIt in pairs(IIfA.data.collectHouseData) do
		local collectibleName = GetCollectibleName(collectibleId)
		--remove gender specific characters from house name
		collectibleName = zo_strformat("<<C:1>>", collectibleName)
		ret[collectibleName] = true
	end
	return ret
end

function IIfA:RebuildHouseMenuDropdowns()
	local tracked = {}
	local ignored = {}
	for collectibleId, trackIt in pairs(IIfA.data.collectHouseData) do
		local collectibleName = GetCollectibleName(collectibleId)
		--remove gender specific characters from house name
		collectibleName = zo_strformat("<<C:1>>", collectibleName)
		-- cache house name for lookup
		IIfA.houseNameToIdTbl[collectibleName] = collectibleId
		local targetTable = (trackIt and tracked) or ignored
		table.insert(targetTable, collectibleName)
	end
	IIfA.houseNamesIgnored = ignored
	IIfA.houseNamesTracked = tracked
end

function IIfA:GetIgnoredHouseNames()
	if nil == IIfA.houseNamesIgnored then
		IIfA:RebuildHouseMenuDropdowns()
	end
	return IIfA.houseNamesIgnored
end

function IIfA:GetTrackedHouseNames()
	if nil == IIfA.houseNamesIgnored then
		IIfA:RebuildHouseMenuDropdowns()
	end
	return IIfA.houseNamesTracked
end

function IIfA:GetAllHouseIds()
	local ret = {}
	for id, trackIt in pairs(IIfA.data.collectHouseData) do
		table.insert(ret, id)
	end
	return ret
end

function IIfA:SetTrackingForHouse(houseCollectibleId, trackIt)
	houseCollectibleId = houseCollectibleId or GetCollectibleIdForHouse(GetCurrentZoneHouseId())
	if tonumber(houseCollectibleId) ~= houseCollectibleId then
		local realId = IIfA:GetHouseIdFromName(houseCollectibleId)
		if not realId then d(houseCollectibleId) return end
		houseCollectibleId = realId
	end
	if houseCollectibleId == 0 then return end
	IIfA.data.collectHouseData[houseCollectibleId] 	= trackIt
	IIfA:GetTrackedBags()[houseCollectibleId] 		= trackIt
	IIfA:RebuildHouseMenuDropdowns()
	if not trackIt then
		IIfA:ClearLocationData(houseCollectibleId)
	else -- try rescanning, in case we are in the house right now
		IIfA:RescanHouse()
	end
end

function IIfA:GetHouseTracking()
	return IIfA.data.b_collectHouses
end

function IIfA:SetHouseTracking(value)
	IIfA.data.b_collectHouses = value
	if value then
		IIfA:RebuildHouseMenuDropdowns()
	end
end
