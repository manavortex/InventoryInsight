local IIfA = IIfA
local EMPTY_STRING = ""

	
local function grabBagContent(bagId)
	local bagItems = GetBagSize(bagId)
	for slotNum=0, bagItems, 1 do
		dbItem, itemKey = IIfA:EvalBagItem(bagId, slotNum)
	end
end

function IIfA:DeleteCharacterData(name)
	if (name) then
		--delete selected character
		for characterName, character in pairs(IIfA.data.accountCharacters) do
			if(characterName == name) then
				IIfA.data.accountCharacters[name] = nil
			end
		end
	end
end

function IIfA:DeleteGuildData(name)
	if (name) then
		--delete selected guild
		for guildName, guild in pairs(IIfA.data.guildBanks) do
			if guildName == name then
				IIfA.data.guildBanks[name] = nil
			end
        end
		IIfA:ClearUnowned()
	end
end

function IIfA:CollectGuildBank()	

	-- add roomba support
	if Roomba and Roomba.WorkInProgress and Roomba.WorkInProgress() then 
		CALLBACK_MANAGER:FireCallbacks("Roomba-EndStacking", function() IIfA:CollectGuildBank() end)
		return
	end
	 
	local curGB = GetSelectedGuildBankId()

	if not IIfA.data.bCollectGuildBankData or curGB == nil then
		return
	end

	if not IIfA.data.guildBanks then IIfA.data.guildBanks = {} end
	local curGuild = GetGuildName(curGB)

	IIfA:DebugOut("Collecting Guild Bank Data for " .. curGuild)

	if IIfA.data.guildBanks[curGuild] ~= nil then
		if not IIfA.data.guildBanks[curGuild].bCollectData then
			return
		end
	end

	SelectGuildBank(CurGB)
	local count = 0

	if(IIfA.data.guildBanks[curGuild] == nil) then
		IIfA.data.guildBanks[curGuild] = {}
		IIfA.data.guildBanks[curGuild].bCollectData = true		-- default to true just so it's here and ok
	end
	local guildData = IIfA.data.guildBanks[curGuild]
	guildData.items = #ZO_GuildBankBackpack.data
	guildData.lastCollected = GetDate() .. "@" .. GetFormattedTime();
	IIfA:ClearLocationData(curGuild)
	IIfA:DebugOut(" - " .. #ZO_GuildBankBackpack.data .. " items")
	for i=1, #ZO_GuildBankBackpack.data do
		local slotIndex = ZO_GuildBankBackpack.data[i].data.slotIndex
		IIfA:EvalBagItem(BAG_GUILDBANK, slotIndex)
	end
--	d("IIfA - Guild Bank Collected - " .. curGuild)
end



local function scanBags()
	local playerName = GetUnitName('player')
	
	IIfA.data.accountCharacters 			= IIfA.data.accountCharacters or {}
	IIfA.data.accountCharacters[playerName] = IIfA.data.accountCharacters[playerName] or {}
			
	IIfA:ClearLocationData(IIfA.currentCharacterId)
	
	if not IIfA:IsCharacterEquipIgnored(playerName) then 
		grabBagContent(BAG_WORN)
	end	
	if not IIfA:IsCharacterInventoryIgnored(playerName) then 
		grabBagContent(BAG_BACKPACK)
	end		
end
IIfA.ScanCurrentCharacter = scanBags

local function tryScanHouseBank()
	if GetAPIVersion() < 100022 then return end
	local bagId = GetBankingBag()
	if not bagId then return end
	local collectibleId = GetCollectibleForHouseBankBag(bagId)

	
	if IsCollectibleUnlocked(collectibleId) then
		local collectibleName = GetCollectibleNickname(collectibleId)
		if collectibleName == EMPTY_STRING then collectibleName = GetCollectibleName(collectibleId) end
		IIfA:ClearLocationData(bagId)
		grabBagContent(bagId)
	end
	
	return true
end

function IIfA:ScanBank()
	if tryScanHouseBank() then return end
	IIfA:ClearLocationData(GetString(IIFA_BAG_BANK))
	grabBagContent(BAG_BANK)
	
	local slotNum = nil
	if HasCraftBagAccess() then		
		grabBagContent(BAG_SUBSCRIBER_BANK)
		IIfA:ClearLocationData(GetString(IIFA_BAG_CRAFTBAG))
		slotNum = GetNextVirtualBagSlotId(slotNum)
		while slotNum ~= nil do
			IIfA:EvalBagItem(BAG_VIRTUAL, slotNum)
			slotNum = GetNextVirtualBagSlotId(slotNum)
		end
	end
end

-- only grabs the content of bagpack and worn on the first login - hence we set the function to insta-return below.
function IIfA:OnFirstInventoryOpen()
	scanBags()
	IIfA:ScanBank()	
	IIfA.OnFirstInventoryOpen = function() return end	
end

function IIfA:CheckForAgedGuildBankData( days )
	local results = false
	local days = days or 5
	if IIfA.data.bCollectGuildBankData then
		IIfA:CleanEmptyGuildBug()
		for guildName, guildData in pairs(IIfA.data.guildBanks)do
			local today = GetDate()
			local lastCollected = guildData.lastCollected:match('(........)')
			if(lastCollected and lastCollected ~= EMPTY_STRING)then
				if(today - lastCollected >= days)then
					d("[IIfA]:Warning - " .. guildName .. " Guild Bank data not collected in " .. days .. " or more days!")
					results = true
				end
			else
				d("[IIfA]:Warning - " .. guildName .. " Guild Bank data has not been collected!")
				results = true
			end
		end
		return results
	end
	return true
end

function IIfA:UpdateGuildBankData()
	if IIfA.data.bCollectGuildBankData then
		local tempGuildBankBag = {
			items = 0;
			lastCollected = EMPTY_STRING;
		}
		for index=1, GetNumGuilds() do
			local guildName = GetGuildName(index)
			local guildBank = IIfA.data.guildBanks[guildName]
			if(not guildBank) then
				IIfA.data.guildBanks[guildName] = tempGuildBankBag
			end
		end
	end
end

function IIfA:CleanEmptyGuildBug()
	local emptyGuild = IIfA.data.guildBanks[EMPTY_STRING]
	if(emptyGuild)then
		IIfA.data.guildBanks[EMPTY_STRING] = nil
	end
end

function IIfA:GuildBankReady()
	IIfA:DebugOut("GuildBankReady...")
	IIfA.isGuildBankReady = false
	IIfA:UpdateGuildBankData()
	IIfA:CleanEmptyGuildBug()
	IIfA:CollectGuildBank()
end

function IIfA:GuildBankDelayReady()
	IIfA:DebugOut("GuildBankDelayReady...")
	if not IIfA.isGuildBankReady then
		IIfA.isGuildBankReady = true
		zo_callLater(function() IIfA:GuildBankReady() end, 1750)
	end
end

function IIfA:GuildBankAddRemove(eventID, slotNum)
	IIfA:DebugOut("Guild Bank Add or Remove...")
	IIfA:UpdateGuildBankData()
	IIfA:CleanEmptyGuildBug()
	--IIfA:CollectGuildBank()
	local dbItem, itemKey
	if eventID == EVENT_GUILD_BANK_ITEM_ADDED then
--		d("GB Add")
		dbItem, itemKey = IIfA:EvalBagItem(BAG_GUILDBANK, slotNum, true, 0)
		IIfA:ValidateItemCounts(BAG_GUILDBANK, slotNum, dbItem, itemKey)
	else
--		d("GB Remove")
--		d(GetItemLink(BAG_GUILDBANK, slotNum))
--		dbItem, itemKey = IIfA:EvalBagItem(BAG_BACKPACK, slotNum)
--		IIfA:ValidateItemCounts(BAG_GUILDBANK, slotNum, dbItem, itemKey)
	end
end

function IIfA:ActionLayerInventoryUpdate()
	-- IIfA:CollectAll()
end


function IIfA:AddFurnitureItem(itemLink, itemCount, houseCollectibleId, fromInitialize)

	local location = houseCollectibleId
	IIfA:EvalBagItem(houseCollectibleId, IIfA:GetItemID(itemLink), false, itemCount, itemLink, GetItemLinkName(itemLink), houseCollectibleId)
end
--[[
Data collection notes:
	Currently crafting items are coming back from getitemlink with level info in them.
	If it's a crafting item, strip the level info and store only the item number as the itemKey
	Use function GetItemCraftingInfo, if usedInCraftingType indicates it's NOT a material, check for other item types

	When showing items in tooltips, check for both stolen & owned, show both
--]]


-- used by an event function - see iifaevents.lua for call
function IIfA:InventorySlotUpdate(eventCode, bagId, slotNum, isNewItem, itemSoundCategory, inventoryUpdateReason, qty)
	if isNewItem then
		isNewItem = "True"
	else
		isNewItem = "False"
	end

	IIfA:DebugOut(zo_strformat("Inv Slot Upd - <<1>>, <<2>>, <<3>>, <<4>>, <<5>>, <<6>>, <<7>>", GetItemLink(bagId, slotNum, LINK_STYLE_NORMAL), eventCode, bagId, slotNum, inventoryUpdateReason, qty, isNewItem))
	local dbItem, itemKey
	dbItem, itemKey = self:EvalBagItem(bagId, slotNum, true, qty)
--	if dbItem ~= nil and (bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK or bagId == BAG_BACKPACK) then
--		IIfA:ValidateItemCounts(bagId, slotNum, dbItem, itemKey)
--	end
end



function IIfA:RescanHouse(houseCollectibleId)
	
	houseCollectibleId = houseCollectibleId or GetCollectibleIdForHouse(GetCurrentZoneHouseId())
	if not houseCollectibleId then return end
	
	if not IIfA:GetTrackedBags()[houseCollectibleId] then return end

	-- it's easier to throw everything away and re-scan than to conditionally update
	IIfA:ClearLocationData(houseCollectibleId)
	
	local function getAllPlacedFurniture()
		local ret = {}
		 while(true) do
			furnitureId = GetNextPlacedHousingFurnitureId(furnitureId)
			if(not furnitureId) then return ret end
			local itemLink = GetPlacedFurnitureLink(furnitureId, LINK_STYLE_BRACKETS)
			if not ret[itemLink] then 
				ret[itemLink] = 1
			else
				ret[itemLink] = ret[itemLink] +1
			end
		end	
	end
	
	local items = getAllPlacedFurniture()
	for itemLink, itemCount in pairs(items) do
		IIfA:AddFurnitureItem(itemLink, itemCount, houseCollectibleId, true)
	end
	
end

local function assertValue(value, itemLink, getFunc)
	if value then return value end
	if getFunc == EMPTY_STRING then return EMPTY_STRING end
	return getFunc(itemLink)
end

local function IIfA_assertItemLink(itemLink, bagId, slotIndex)
	if itemLink ~= nil then
		return itemLink
	else
		if (bagId ~= nil and slotIndex ~= nil) then
			return GetItemLink(tonumber(bagId), tonumber(slotIndex))
		end
	end

	return nil
end

local function setItemFileEntry(array, key, value)
	if not value then return end
	if not array then return end
	if not array[key] then
		array[key] = {}
	end

	array[key] = value
end

function IIfA:AddOrRemoveFurnitureItem(itemLink, itemCount, houseCollectibleId, fromInitialize)
	-- d(zo_strformat("trying to add/remove <<1>> x <<2>> from houseCollectibleId <<3>>", itemLink, itemCount, houseCollectibleId))
	local location = houseCollectibleId
	IIfA:EvalBagItem(houseCollectibleId, IIfA:GetItemID(itemLink), false, itemCount, itemLink, GetItemLinkName(itemLink), houseCollectibleId)
end

function IIfA:EvalBagItem(bagId, slotNum, fromXfer, itemCount, itemLink, itemName, locationID)
	if not IIfA.trackedBags[bagId] then return end
	
	IIfA.data.DBv3 = IIfA.data.DBv3 or {}
	local DBv3 = IIfA.data.DBv3

	if fromXfer == nil then
		fromXfer = false
	end

	itemName = itemName or GetItemName(bagId, slotNum) or EMPTY_STRING

	IIfA:DebugOut(zo_strformat("EvalBagItem - <<1>>/<<2>> <<3>>", bagId, slotNum, itemName))

	if itemName > EMPTY_STRING then
		itemLink = itemLink or GetItemLink(bagId, slotNum, LINK_STYLE_BRACKETS)
		itemKey = itemLink
		local usedInCraftingType, itemType, extraInfo1, extraInfo2, extraInfo3 = GetItemCraftingInfo(bagId, slotNum)

		if usedInCraftingType ~= CRAFTING_TYPE_INVALID and
		   itemType ~= ITEMTYPE_GLYPH_ARMOR and
		   itemType ~= ITEMTYPE_GLYPH_JEWELRY and
		   itemType ~= ITEMTYPE_GLYPH_WEAPON then
		   itemKey = IIfA:GetItemID(itemLink)
		else
			itemType = GetItemLinkItemType(itemLink)
			if  itemType == ITEMTYPE_STYLE_MATERIAL or
				itemType == ITEMTYPE_ARMOR_TRAIT or
				itemType == ITEMTYPE_WEAPON_TRAIT or
				itemType == ITEMTYPE_LOCKPICK or
				itemType == ITEMTYPE_RAW_MATERIAL or
				itemType == ITEMTYPE_RACIAL_STYLE_MOTIF or		-- 9-12-16 AM - added because motifs now appear to have level info in them
				itemType == ITEMTYPE_RECIPE then
				itemKey = IIfA:GetItemID(itemLink)
			end
		end
		local qty, equipType, itemQuality
		if not itemLink then 
			_, qty, _, _, _, equipType, _, itemQuality = GetItemInfo(bagId, slotNum)
		else
			qty = 1
			equipType =  GetItemLinkEquipType(itemLink)
			itemQuality = GetItemLinkQuality(itemLink)
		end
		itemCount = itemCount or qty
		itemFilterType = GetItemFilterTypeInfo(bagId, slotNum) or 0
		DBitem = DBv3[itemKey]
		location = locationID or EMPTY_STRING
		if(equipType == 0 or bagId ~= BAG_WORN) then equipType = false end
		if(bagId == BAG_BACKPACK or bagId == BAG_WORN) then
			location = IIfA.currentCharacterId

		elseif(bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK) then
			location = GetString(IIFA_BAG_BANK)
		elseif(bagId == BAG_VIRTUAL) then
			location =GetString(IIFA_BAG_CRAFTBAG)
		elseif(bagId == BAG_GUILDBANK) then
			location = GetGuildName(GetSelectedGuildBankId())
		elseif GetAPIVersion() >= 100022 and 0 < GetCollectibleForHouseBankBag(bagId) then
			location = GetCollectibleForHouseBankBag(bagId)
		
		-- elseif GetAPIVersion() >= 100022 then
			-- local collectibleId = GetCollectibleForHouseBankBag(GetBankingBag())
			-- location = GetCollectibleNickname(collectibleId)
			-- if location == EMPTY_STRING then location = GetCollectibleName(collectibleId) end
		end
		
		if(DBitem) then
			DBitemlocation = DBitem.locations[location]
			if DBitemlocation then
				DBitemlocation.itemCount = DBitemlocation.itemCount + itemCount
				DBitemlocation.bagSlot = DBitemlocation.bagSlot or slotNum
			else
				DBitem.locations[location] = {}
				DBitem.locations[location].bagID = bagId
				DBitem.locations[location].bagSlot = slotNum
				DBitem.locations[location].itemCount = itemCount
			end
		else
			DBv3[itemKey] = {}
			DBv3[itemKey].filterType = itemFilterType
			DBv3[itemKey].itemQuality = itemQuality
			DBv3[itemKey].itemName = itemName
			DBv3[itemKey].locations = {}
			DBv3[itemKey].locations[location] = {}
			DBv3[itemKey].locations[location].bagID = bagId
			DBv3[itemKey].locations[location].bagSlot = slotNum
			DBv3[itemKey].locations[location].itemCount = itemCount
		end
		if zo_strlen(itemKey) < 10 then
			DBv3[itemKey].itemLink = itemLink
		end
		if (IIfA.trackedBags[bagId]) and fromXfer then
			IIfA:ValidateItemCounts(bagId, slotNum, DBv3[itemKey], itemKey, itemLink, true)
		end

	  	return DBv3[itemKey], itemKey
	else
		return nil
	end
end

function IIfA:ValidateItemCounts(bagID, slotNum, dbItem, itemKey, itemLinkOverride, override)
	local itemLink, itemLinkCheck
	if zo_strlen(itemKey) < 10 then
		itemLink = GetItemLink(bagID, slotNum) or dbItem.itemLink or (override and itemLinkOverride)
	else
		itemLink = itemKey
	end
	IIfA:DebugOut(zo_strformat("ValidateItemCounts: <<1>>x<<3>> in <<2>>", itemLink, bagID, slotNum))

	for locName, data in pairs(dbItem.locations) do
--		if data.bagID ~= nil then	-- it's an item, not attribute
			if (data.bagID == BAG_GUILDBANK and locName == GetGuildName(GetSelectedGuildBankId())) or	
			-- we're looking at the right guild bank
			    data.bagID == BAG_VIRTUAL or
				data.bagID == BAG_BANK or
				data.bagID == BAG_SUBSCRIBER_BANK or 
				nil ~= GetCollectibleForHouseBankBag and nil ~= GetCollectibleForHouseBankBag(data.bagID) or -- is housing bank, manaeeee
			   ((data.bagID == BAG_BACKPACK or data.bagID == BAG_WORN) and locName == GetCurrentCharacterId()) then
--		d(locName)
--		d(data)
--		d(GetItemLink(data.bagID, data.bagSlot, LINK_STYLE_BRACKETS))
				itemLinkCheck = GetItemLink(data.bagID, data.bagSlot, LINK_STYLE_BRACKETS)
				if itemLinkCheck == nil then
					itemLinkCheck = (override and itemLinkOverride) or EMPTY_STRING
				end
--				d("ItemlinkCheck = " .. itemLinkCheck)
				if itemLinkCheck ~= itemLink then
					if bagID ~= data.bagID and slotNum ~= data.bagSlot then
--						d("should remove " .. itemLink .. " from " .. locName)
					-- it's no longer the same item, or it's not there at all
						self.data.DBv3[itemKey].locations[locName] = nil
					end
				end
			end
--		end
	end
end


function IIfA:CollectAll()
	local bagItems = nil
	local itemLink, dbItem = nil
	local itemKey
	local location = EMPTY_STRING
	local BagList = IIfA:GetTrackedBags() -- 20.1. mana: Iterating over a list now

	for bagId, tracked in ipairs(BagList) do
		
		bagItems = GetBagSize(bagId)
		if(bagId == BAG_WORN)then	--location for BAG_BACKPACK and BAG_WORN is the same so only reset once
			IIfA:ClearLocationData(IIfA.currentCharacterId)
		elseif(bagId == BAG_BANK) then	-- do NOT add BAG_SUBSCRIBER_BANK here, it'll wipe whatever already got put into the bank on first hit
			IIfA:ClearLocationData(GetString(IIFA_BAG_BANK))
		elseif(bagId == BAG_VIRTUAL)then
			IIfA:ClearLocationData(GetString(IIFA_BAG_CRAFTBAG))
		elseif GetAPIVersion() >= 100022 then -- 20.1. mana: bag bag bag
			local collectibleId = GetCollectibleForHouseBankBag(bagId)
			if IsCollectibleUnlocked(collectibleId) then
				local name = GetCollectibleNickname(collectibleId) or GetCollectibleName(collectibleId)
				IIfA:ClearLocationData(name)
			end
		end
--		d("  BagItemCount=" .. bagItems)
		if bagId ~= BAG_VIRTUAL and tracked then
			for slotNum=0, bagItems, 1 do
				dbItem, itemKey = IIfA:EvalBagItem(bagId, slotNum)
			end
		else
			if HasCraftBagAccess() then
				slotNum = GetNextVirtualBagSlotId(nil)
				while slotNum ~= nil do
					IIfA:EvalBagItem(bagId, slotNum)
					slotNum = GetNextVirtualBagSlotId(slotNum)
				end
			end
		end
	end

	-- 6-3-17 AM - need to clear unowned items when deleting char/guildbank too
	IIfA:ClearUnowned()
end

function IIfA:TrySaveBagInfo()
	
end

function IIfA:ClearUnowned()
-- 2015-3-7 Assembler Maniac - new code added to go through full inventory list, remove any un-owned items
	local DBv3 = IIfA.data.DBv3
	local n, ItemLink, DBItem
	local ItemOwner, ItemData
	for ItemLink, DBItem in pairs(DBv3) do
		n = 0
		for ItemOwner, ItemData in pairs(DBItem.locations) do
			n = n + 1
			if ItemOwner ~= "Bank" and ItemOwner ~= "CraftBag" then
				if ItemData.bagID == BAG_BACKPACK or ItemData.bagID == BAG_WORN then
					if IIfA.CharIdToName[ItemOwner] == nil then
						DBItem[ItemOwner] = nil
	  				end
				elseif ItemData.bagID == BAG_GUILDBANK then
					if IIfA.data.guildBanks[ItemOwner] == nil then
						DBItem[ItemOwner] = nil
					end
				end
			end
		end
		if (n == 0) then
			DBv3[ItemLink] = nil
		end
	end
-- 2015-3-7 end of addition
end


function IIfA:ClearLocationData(location)
	local DBv3 = IIfA.data.DBv3
	local itemLocation = nil
	local LocationCount = 0
	local itemName, itemData

	if(DBv3)then
		for itemName, itemData in pairs(IIfA.data.DBv3) do
			itemLocation = itemData.locations[location]
			if (itemLocation) then
				itemData.locations[location] = nil
			end
			LocationCount = 0
			for locName, location in pairs(itemData.locations) do
				LocationCount = LocationCount + 1
				break
			end
			if(LocationCount == 0)then
				DBv3[itemName] = nil
			end
		end
	end
end

-- rewrite item links with proper level value in them, instead of random value based on who knows what
-- written by SirInsidiator
local function RewriteItemLink(itemLink)
    local requiredLevel = select(6, ZO_LinkHandler_ParseLink(itemLink))
    requiredLevel = tonumber(requiredLevel)
    local trueRequiredLevel = GetItemLinkRequiredLevel(itemLink)

    itemLink = string.gsub(itemLink, "|H(%d):item:(.*)" , "|H0:item:%2")

    if requiredLevel ~= trueRequiredLevel then
        itemLink = string.gsub(itemLink, "|H0:item:(%d+):(%d+):(%d+)(.*)" , "|H0:item:%1:%2:".. trueRequiredLevel .."%4")
    end

    return itemLink
end

local function GetItemIdentifier(itemLink)
    local itemType = GetItemLinkItemType(itemLink)
    local data = {zo_strsplit(":", itemLink:match("|H(.-)|h.-|h"))}
    local itemId = data[3]
    local level = GetItemLinkRequiredLevel(itemLink)
    local cp = GetItemLinkRequiredChampionPoints(itemLink)
--	local results
--	results.itemId = itemId
--	results.itemType = itemType
--	results.level = level
--	results.cp = cp
    if(itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR) then
        local trait = GetItemLinkTraitInfo(itemLink)
        return string.format("%s,%s,%d,%d,%d", itemId, data[4], trait, level, cp)
    elseif(itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_POTION) then
        return string.format("%s,%d,%d,%s", itemId, level, cp, data[23])
    elseif(hasDifferentQualities[itemType]) then
        return string.format("%s,%s", itemId, data[4])
    else
        return itemId
    end
end

function IIfA:RenameItems()
	local DBv3 = IIfA.data.DBv3
	local item = nil
	local itemName

	if(DBv3)then
		for item, itemData in pairs(DBv3) do
			itemName = nil
			if item:match("|H") then
				itemName = GetItemLinkName(item)
			else
				itemName = GetItemLinkName(itemData.itemLink)
			end
			if itemName ~= nil then
				itemData.itemName = itemName
			end
		end
	end
end


