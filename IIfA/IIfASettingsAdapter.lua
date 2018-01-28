 local IIfA = IIfA
 
 
function IIfA:IsCharacterInventoryIgnored(ignoreChar)
	return IIfA.data.ignoredCharEquipment[ignoreChar]
end

function IIfA:IsCharacterEquipIgnored(ignoreChar)
	return IIfA.data.ignoredCharInventories[ignoreChar]
end

function IIfA:IgnoreCharacterEquip(ignoreChar, value)
	IIfA.data.ignoredCharEquipment[ignoreChar] = value
	if value then
		IIfA:ScanCurrentCharacter()
	else
		IIfA:ClearLocationData(IIfA.currentCharacterId)
	end
end
function IIfA:IgnoreCharacterInventory(ignoreChar, value)
	IIfA.data.ignoredCharInventories[ignoreChar] = value
	IIfA:ScanCurrentCharacter()
end
function IIfA:GetCharacterList()
	return IIfA.data.accountCharacters
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
	IIFA_GUI_SetNameOnly:SetState((IIfA.bFilterOnSetName and BSTATE_PRESSED) or BSTATE_NORMAL)
    IIfA:UpdateScrollDataLinesData()
    IIfA:UpdateInventoryScroll()
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


function IIfA:SetInventoryListFilter(value)
	if not value or value == "" then value = "All" end
	IIfA.InventoryListFilter = value

	IIfA.searchFilter = IIFA_GUI_SearchBox:GetText()

	IIfA:UpdateScrollDataLinesData()
	IIfA:UpdateInventoryScroll()
end

-- this is for the dropdown menu
function IIfA:GetInventoryListFilterQuality()
	return IIfA.InventoryListFilterQuality or 99
end


-- this is for the dropdown menu
function IIfA:SetInventoryListFilterQuality(value)
	IIfA.InventoryListFilterQuality = value
	
	IIfA.searchFilter = IIFA_GUI_SearchBox:GetText()
	
	IIfA:UpdateScrollDataLinesData()
    IIfA:UpdateInventoryScroll()
end
function IIfA:GetCollectingHouseData()
	return IIfA.data.collectHouseData.All
end
function IIfA:SetCollectingHouseData(value)
	IIfA.data.collectHouseData.All = value
	for houseName, houseId in pairs(IIfA:GetHouseList()) do
		IIfA:SetCollectHouseStatus(houseName, value)
	end
end
function IIfA:SetCollectHouseStatus(houseName, value)
	local houseId = IIfA:GetHouseList()[houseName]
	IIfA.data.collectHouseData[houseId] = value
	IIfA:GetTrackedBags()[houseId] 		= value
	if not value then
		IIfA:ClearLocationData(houseId)
	end
end

function IIfA:GetTrackedBags()
	return IIfA.trackedBags
end