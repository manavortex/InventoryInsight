local IIfA 			= IIfA
local EMPTY_STRING 	= ""
local _

local task 			= IIfA.task or LibStub("LibAsync"):Create("IIfA_DataCollection")
IIfA.task			= task

local function p(...) IIfA:DebugOut(...) end

local function grabBagContent(bagId, override)
	if bagId >= BAG_HOUSE_BANK_ONE and bagId <= BAG_HOUSE_BANK_TEN and not IsOwnerOfCurrentHouse() then return end

	local bagItems = GetBagSize(bagId)
	IIfA:DebugOut("grabBagContent(<<1>>, <<2>>", bagId, override)
	for slotId=0, bagItems, 1 do
		local dbItem, itemKey = IIfA:EvalBagItem(bagId, slotId, false, nil, nil, nil, nil, override)
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

	-- call with libAsync to avoid lag
	task:Call(function()
		IIfA:DebugOut("Collect guild bank - <<1>>", curGuild)
		local guildData = IIfA.data.guildBanks[curGuild]
		guildData.items = #ZO_GuildBankBackpack.data
		guildData.lastCollected = GetDate() .. "@" .. GetFormattedTime();
		IIfA:ClearLocationData(curGuild)
		IIfA:DebugOut(" - " .. #ZO_GuildBankBackpack.data .. " items")
		for i=1, #ZO_GuildBankBackpack.data do
			local slotIndex = ZO_GuildBankBackpack.data[i].data.slotIndex
			IIfA:EvalBagItem(BAG_GUILDBANK, slotIndex)
		end
	end)
--	d("IIfA - Guild Bank Collected - " .. curGuild)
end



function IIfA:ScanCurrentCharacter()

	local playerName = GetUnitName('player')

	IIfA.data.accountCharacters 			= IIfA.data.accountCharacters or {}
	IIfA.data.accountCharacters[playerName] = IIfA.data.accountCharacters[playerName] or {}

	IIfA:ClearLocationData(IIfA.currentCharacterId)

	if not IIfA:IsCharacterEquipIgnored() then
		-- call with libAsync to avoid lags
		task:Call(function()
			grabBagContent(BAG_WORN)
		end)
	end
	if not IIfA:IsCharacterInventoryIgnored() then
		-- call with libAsync to avoid lags
		task:Call(function()
			grabBagContent(BAG_BACKPACK)
		end)
	end
	task:Call(function()
		IIfA:MakeBSI()
	end)
end

--[[
Developer note: In TryScanHouseBank, the call to IIfA:ClearLocationData will fail because collectibleId is zero
bagId on the other hand DOES work, possibly because it's in use by the for loop
]]--

local function tryScanHouseBank()
	if not IsOwnerOfCurrentHouse() then return end

	local bagId, collectibleId
	for bagId = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
		collectibleId = GetCollectibleForHouseBankBag(bagId)
		if IsCollectibleUnlocked(collectibleId) then
			IIfA:DebugOut(zo_strformat("tryScanHouseBank(<<1>>)", collectibleId))
			-- call with libAsync to avoid lag
			task:Call(function()
				local collectibleId = GetCollectibleForHouseBankBag(bagId)		-- required code - MUST stay here, or collectibleId is 0
				IIfA:ClearLocationData(collectibleId)
			end):Then(function()
				grabBagContent(bagId, true)
			end)
		end
	end
end

function IIfA:ScanBank()
	-- call with libAsync to avoid lag
	task:Call(function()
		IIfA:ClearLocationData(GetString(IIFA_BAG_BANK))
	end):Then(function()
		grabBagContent(BAG_BANK)
	end):Then(function()
		grabBagContent(BAG_SUBSCRIBER_BANK)
	end):Then(function()
		IIfA:ClearLocationData(GetString(IIFA_BAG_CRAFTBAG))
		local slotId = GetNextVirtualBagSlotId(slotId)
		while slotId ~= nil do
			IIfA:EvalBagItem(BAG_VIRTUAL, slotId)
			slotId = GetNextVirtualBagSlotId(slotId)
		end
	end):Then(function()
		tryScanHouseBank()
	end)
end


-- only grabs the content of bagpack and worn on the first login - hence we set the function to insta-return below.
function IIfA:OnFirstInventoryOpen()

	if IIfA.BagsScanned then return end
	IIfA.BagsScanned = true

	-- call with libAsync to avoid lags
	task:Call(function()
		IIfA:ScanBank()
	end):Then(function()
		IIfA:ScanCurrentCharacter()
	end)
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
	-- call with libAsync to avoid lags
	task:Call(function()
		IIfA:DebugOut("GuildBankReady...")
		IIfA.isGuildBankReady = false
		IIfA:UpdateGuildBankData()
	end):Then(function()
		IIfA:CleanEmptyGuildBug()
	end):Then(function()
		IIfA:CollectGuildBank()
	end)
end

function IIfA:GuildBankDelayReady()
	IIfA:DebugOut("GuildBankDelayReady...")
	if not IIfA.isGuildBankReady then
		IIfA.isGuildBankReady = true
		-- call with libAsync to avoid lags
		task:Call(function()
			IIfA:GuildBankReady()
		end)
	end
end

function IIfA:GuildBankAddRemove(eventID, slotId)
	IIfA:DebugOut("Guild Bank Add or Remove...")
	-- call with libAsync to avoid lag
	task:Call(function()
		IIfA:UpdateGuildBankData()
		IIfA:CleanEmptyGuildBug()
	end):Then(function()
	--IIfA:CollectGuildBank()
		local dbItem, itemKey
		if eventID == EVENT_GUILD_BANK_ITEM_ADDED then
			IIfA:DebugOut("GB Add - Slot <<1>>", slotId)
			dbItem, itemKey = IIfA:EvalBagItem(BAG_GUILDBANK, slotId, true, 0)
			IIfA:ValidateItemCounts(BAG_GUILDBANK, slotId, dbItem, itemKey)
		else
	--		d("GB Remove")
	--		d(GetItemLink(BAG_GUILDBANK, slotId))
	--		dbItem, itemKey = IIfA:EvalBagItem(BAG_BACKPACK, slotId)
	--		IIfA:ValidateItemCounts(BAG_GUILDBANK, slotId, dbItem, itemKey)
		end
	end)
end

function IIfA:ActionLayerInventoryUpdate()
	-- IIfA:CollectAll()
end


--[[
Data collection notes:
	Currently crafting items are coming back from getitemlink with level info in them.
	If it's a crafting item, strip the level info and store only the item number as the itemKey
	Use function GetItemCraftingInfo, if usedInCraftingType indicates it's NOT a material, check for other item types

	When showing items in tooltips, check for both stolen & owned, show both
--]]

function IIfA:RescanHouse(houseCollectibleId)

	houseCollectibleId = houseCollectibleId or GetCollectibleIdForHouse(GetCurrentZoneHouseId())
	if not houseCollectibleId then return end


	IIfA.data.collectHouseData[houseCollectibleId] = IIfA.data.collectHouseData[houseCollectibleId] or IIfA:GetHouseTracking()

	if not IIfA.data.collectHouseData[houseCollectibleId] then
		if IIfA:GetHouseTracking() and IIfA:GetIgnoredHouseIds()[houseCollectibleId] then
			IIfA.trackedBags[houseCollectibleId] = false
			return
		end
		IIfA.trackedBags[houseCollectibleId] = true
	end

	--- stuff them all into an array
	local function getAllPlacedFurniture()
		local ret = {}
		 while(true) do
			furnitureId = GetNextPlacedHousingFurnitureId(furnitureId)
			if(not furnitureId) then return ret end
			local itemLink = GetPlacedFurnitureLink(furnitureId, LINK_STYLE_BRACKETS)
			if not ret[itemLink] then
				ret[itemLink] = 1
			else
				ret[itemLink] = ret[itemLink] + 1
			end
		end
	end

	-- call with libAsync to avoid lags
	task:Call(function()
		-- clear and re-create, faster than conditionally updating
		IIfA:ClearLocationData(houseCollectibleId)
	end):Then(function()
		for itemLink, itemCount in pairs(getAllPlacedFurniture()) do
			-- (bagId, slotId, fromXfer, itemCount, itemLink, itemName, locationID)
			IIfA:DebugOut("furniture item <<1>> x<<2>>", itemLink, itemCount)
			IIfA:EvalBagItem(houseCollectibleId, tonumber(IIfA:GetItemID(itemLink)), false, itemCount, itemLink, GetItemLinkName(itemLink), houseCollectibleId)

		end
	end)

end

--[[ causing massive problems because we're creating the BSI entry while trying to use it from EvalBagItem
-- try to read item link from bag/slot - if that's an empty string, we try to read it from BSI
local function getItemLink(bagId, slotId)
	if nil == bagId or nil == slotId then return end
	local itemLink = GetItemLink(bagId, slotId, LINK_STYLE_BRACKETS)
	if itemLink ~= "" then
		-- got an item link, save it to the BSI for reverse lookups
		IIfA:SaveBagSlotIndex(bagId, slotId, itemLink)
		return itemLink
	end
	if not IIfA.BagSlotInfo then return end
	if nil == IIfA.BagSlotInfo[bagId] then return end
	return IIfA.BagSlotInfo[bagId][slotId]
end
--]]

-- try to read item name from bag/slot - if that's empty, we read it from item link
local function getItemName(bagId, slotId, itemLink)
	local itemName = GetItemName(bagId, slotId)
	if "" ~= itemName then return itemName end
	if nil == itemLink then return end
	return GetItemLinkName(itemLink)
end

-- returns the item's db key, we only save under the item link if we need to save level information etc, else we use the ID
function IIfA:GetItemKey(itemLink, usedInCraftingType, itemType)

	if CanItemLinkBeVirtual(itemLink) then	-- anything that goes in the craft bag
		return IIfA:GetItemID(itemLink)
	elseif usedInCraftingType ~= CRAFTING_TYPE_INVALID and		-- crafting materials get saved by ID
   		itemType ~= ITEMTYPE_GLYPH_ARMOR and
   		itemType ~= ITEMTYPE_GLYPH_JEWELRY and
   		itemType ~= ITEMTYPE_GLYPH_WEAPON then
   		return IIfA:GetItemID(itemLink)
	else
		-- other oddball items that might have level info in them
		itemType = itemType or GetItemLinkItemType(itemLink)
		if	itemType == ITEMTYPE_LOCKPICK or
			itemType == ITEMTYPE_RACIAL_STYLE_MOTIF or		-- 9-12-16 AM - added because motifs now appear to have level info in them
			itemType == ITEMTYPE_RECIPE then
			return IIfA:GetItemID(itemLink)
		end
	end
	return itemLink
end

local function getItemCount(bagId, slotId, itemLink)

	local stackCountBackpack, stackCountBank, stackCountCraftBag, itemCount
	-- first try to read item count from bag/slot
	_, itemCount =  GetItemInfo(bagId, slotId)
	if 0 < itemCount then return itemCount end

	-- try to find it by item link - only works for bag_backpack / bank / virtual
	stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
	if 		bagId == BAG_BACKPACK 	and 0 < stackCountBackpack 	then return stackCountBackpack
	elseif 	bagId == BAG_BANK 		and 0 < stackCountBank 		then return stackCountBank
	elseif 	bagId == BAG_VIRTUAL 	and 0 < stackCountCraftBag 	then return stackCountCraftBag
	elseif  bagId == BAG_WORN then return 1 end

	-- return 0 if no item count was found, possibly an out of date index to a house container that no longer exists
	return 0
end

local function getLocation(location, bagId)
	if(bagId == BAG_BACKPACK or bagId == BAG_WORN) then
		return IIfA.currentCharacterId
	elseif(bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK) then
		return GetString(IIFA_BAG_BANK)
	elseif(bagId == BAG_VIRTUAL) then
		return GetString(IIFA_BAG_CRAFTBAG)
	elseif(bagId == BAG_GUILDBANK) then
		return GetGuildName(GetSelectedGuildBankId())
	elseif 0 < GetCollectibleForHouseBankBag(bagId) then
		return GetCollectibleForHouseBankBag(bagId)
	end
end

function IIfA:SaveBagSlotIndex(bagId, slotId, itemLink)
	if not bagId or not slotId then return end
	IIfA.BagSlotInfo = IIfA.BagSlotInfo or IIfA:MakeBSI()
	IIfA.BagSlotInfo[bagId] = IIfA.BagSlotInfo[bagId] or {}
	IIfA.BagSlotInfo[bagId][slotId] = IIfA.BagSlotInfo[bagId][slotId] or itemLink
end

function IIfA:AddOrRemoveFurnitureItem(itemLink, itemCount, houseCollectibleId, fromInitialize)
	-- d(zo_strformat("trying to add/remove <<1>> x <<2>> from houseCollectibleId <<3>>", itemLink, itemCount, houseCollectibleId))
	local location = houseCollectibleId
	IIfA:EvalBagItem(houseCollectibleId, IIfA:GetItemID(itemLink), false, itemCount, itemLink, GetItemLinkName(itemLink), houseCollectibleId)
end

function IIfA:EvalBagItem(bagId, slotId, fromXfer, itemCount, itemLink, itemName, locationID)

	if not IIfA.trackedBags[bagId] then return end

	IIfA.database = IIfA.database or {}
	local DBv3 = IIfA.database

	-- item link is either passed as arg or we need to read it from the system
	itemLink = itemLink or GetItemLink(bagId, slotId)
	itemLink = string.gsub(itemLink, '|H0', '|H1')		-- always store/eval with brackets on the link

	--IIfA:DebugOut("trying to save <<1>> x<<2>>", itemLink, itemCount)

	-- return if we don't have any item to track
	if itemLink == nil or itemLink == "" then return end

	-- item names is either passed or we get it from bag/slot or item link
	itemName = itemName or getItemName(bagId, slotId, itemLink) or EMPTY_STRING

	-- item count is either passed or we have to get it from bag/slot ID or item link
	itemCount = itemCount or getItemCount(bagId, slotId, itemLink)


	-- get item key from crafting type
	local usedInCraftingType, itemType
	local qty, itemQuality

	if bagId <= BAG_MAX_VALUE then
		usedInCraftingType, _ = GetItemCraftingInfo(bagId, slotId)
		_, qty, _, _, _, _, _, itemQuality = GetItemInfo(bagId, slotId)
	else	-- these are furniture items in a house
		usedInCraftingType = GetItemLinkCraftingSkillType(itemLink)
		qty = itemCount or 0
		itemQuality = GetItemLinkQuality(itemLink)
	end

	local itemType = GetItemLinkItemType(itemLink)

	-- IIfA:DebugOut("CraftingType, ItemType <<1>>, <<2>>", usedInCraftingType, itemType)


	if 0 == qty and itemLink then
		itemQuality			= GetItemLinkQuality(itemLink)
		usedInCraftingType 	= GetItemLinkCraftingSkillType(itemLink)
		itemType 			= GetItemLinkItemType(itemLink)
	end

	itemLink = string.gsub(itemLink, '|H0', '|H1')

	local itemKey
	if bagId == BAG_VIRTUAL then
		itemKey = tostring(slotId)
	else
		itemKey = IIfA:GetItemKey(itemLink, usedInCraftingType, itemType) or itemLink
	end


	if nil == itemKey then return end

	local itemFilterType = GetItemFilterTypeInfo(bagId, slotId) or 0
	local DBitem = DBv3[itemKey]
	local location = locationID or getLocation(location, bagId) or EMPTY_STRING

	if(DBitem) then
		local DBitemlocation = DBitem.locations[location]
		if DBitemlocation then
			DBitemlocation.itemCount = DBitemlocation.itemCount + itemCount
			DBitemlocation.bagSlot = DBitemlocation.bagSlot or slotId
		else
			DBitem.locations[location] = {}
			DBitem.locations[location].bagID = bagId
			DBitem.locations[location].bagSlot = slotId
			DBitem.locations[location].itemCount = itemCount
		end
		if qty < 1 then
			qty = getItemCount(bagId, slotId, itemLink)
			if qty == 0 then
				DBitem.locations[location] = nil
			else
				DBitem.locations[location].itemCount = qty
			end
		end
	else
		DBv3[itemKey] = {}
		DBv3[itemKey].filterType = itemFilterType
		DBv3[itemKey].itemQuality = itemQuality
		DBv3[itemKey].itemName = itemName
		DBv3[itemKey].locations = {}
		DBv3[itemKey].locations[location] = {}
		DBv3[itemKey].locations[location].bagID = bagId
		DBv3[itemKey].locations[location].bagSlot = slotId
		DBv3[itemKey].locations[location].itemCount = itemCount
	end

	if zo_strlen(itemKey) < 10 then
		DBv3[itemKey].itemLink = itemLink
	end
	if (IIfA.trackedBags[bagId]) and fromXfer then
		IIfA:ValidateItemCounts(bagId, slotId, DBv3[itemKey], itemKey, itemLink, true)
	end

	IIfA:DebugOut("saved bag/slot=<<1>>/<<2>> <<3>> x<<4>> -> <<5>>, loc=<<6>>", bagId, slotId, itemLink, itemCount, itemKey, location)

	return DBv3[itemKey], itemKey

end

function IIfA:ValidateItemCounts(bagID, slotId, dbItem, itemKey, itemLinkOverride, override)

	local itemCount
	local itemLink, itemLinkCheck
	if zo_strlen(itemKey) < 10 then
		itemLink = dbItem.itemLink or GetItemLink(bagID, slotId) or (override and itemLinkOverride)
	else
		itemLink = itemKey
	end
	IIfA:DebugOut(zo_strformat("ValidateItemCounts: <<1>> in bag <<2>>/<<3>>", itemLink, bagID, slotId))

	for locName, data in pairs(dbItem.locations) do
		if (data.bagID == BAG_GUILDBANK and locName == GetGuildName(GetSelectedGuildBankId())) or
		-- we're looking at the right guild bank
			data.bagID == BAG_VIRTUAL or
			data.bagID == BAG_BANK or
			data.bagID == BAG_SUBSCRIBER_BANK or
			nil ~= GetCollectibleForHouseBankBag and nil ~= GetCollectibleForHouseBankBag(data.bagID) or -- is housing bank, manaeeee
		   ((data.bagID == BAG_BACKPACK or data.bagID == BAG_WORN) and locName == GetCurrentCharacterId()) then

			itemLinkCheck = GetItemLink(data.bagID, data.bagSlot, LINK_STYLE_BRACKETS)
			if itemLinkCheck == nil then
				itemLinkCheck = (override and itemLinkOverride) or EMPTY_STRING
			end
			if itemLinkCheck ~= itemLink then
				if bagID ~= data.bagID and slotId ~= data.bagSlot then
				-- it's no longer the same item, or it's not there at all
					IIfA.database[itemKey].locations[locName] = nil
				end
			-- item link is valid, just make sure we have our count right
			elseif bagId == data.bagID then
					_, data.itemCount = GetItemInfo(bagID, slotId)

			end
		end
	end
end


function IIfA:CollectAll(bagId, tracked)		-- the args aren't used, but by making them args to function, they're avail to the task
	local bagItems = nil
	local itemLink, dbItem = nil
	local itemKey
	local location = EMPTY_STRING
	local BagList = IIfA:GetTrackedBags() -- 20.1. mana: Iterating over a list now

	for bagId, tracked in pairs(BagList) do		-- do NOT use ipairs, it's non-linear list (holes in the # sequence)
		if bagId <= BAG_MAX_VALUE then
			-- call with libAsync to avoid lags
			task:Call(function()
				bagItems = GetBagSize(bagId)
				if bagId == BAG_WORN then
					IIfA:ClearLocationData(IIfA.currentCharacterId, BAG_WORN)
				elseif bagId == BAG_BANK then	-- do NOT add BAG_SUBSCRIBER_BANK here, it'll wipe whatever already got put into the bank on first hit
					IIfA:ClearLocationData(GetString(IIFA_BAG_BANK))
				elseif bagId == BAG_BACKPACK then
					IIfA:ClearLocationData(IIfA.currentCharacterId, BAG_BACKPACK)
				elseif bagId == BAG_VIRTUAL then
					IIfA:ClearLocationData(GetString(IIFA_BAG_CRAFTBAG))
				elseif bagId >= BAG_HOUSE_BANK_ONE and bagId <= BAG_HOUSE_BANK_TEN then
					if IsOwnerOfCurrentHouse() then
						IIfA:ClearLocationData(GetCollectibleForHouseBankBag(bagId))
					else
						tracked = false		-- prevent reading the house bag if we're not in our own home
					end
				end
				if tracked then
					if bagId ~= BAG_VIRTUAL then
						if bagId ~= BAG_SUBSCRIBER_BANK then
							grabBagContent(bagId)
							if bagId == BAG_BANK then
								grabBagContent(BAG_SUBSCRIBER_BANK)
							end
						end
					else -- it's bag virtual
						local slotId = GetNextVirtualBagSlotId(nil)
						while slotId ~= nil do
							IIfA:EvalBagItem(bagId, slotId)
							slotId = GetNextVirtualBagSlotId(slotId)
						end
					end
				end

			end)
		end
	end

	-- 6-3-17 AM - need to clear unowned items when deleting char/guildbank too
	IIfA:ClearUnowned()
	zo_callLater(function()
		IIfA:MakeBSI()
	end, 1000)
end


function IIfA:ClearUnowned()
-- 2015-3-7 Assembler Maniac - new code added to go through full inventory list, remove any un-owned items
	local n, ItemLink, DBItem
	local ItemOwner, ItemData
	for ItemLink, DBItem in pairs(IIfA.database) do
		n = 0
		for ItemOwner, ItemData in pairs(DBItem.locations) do
			n = n + 1
			if ItemOwner ~= "Bank" and ItemOwner ~= "CraftBag" then
				if ItemData.bagID == BAG_BACKPACK or ItemData.bagID == BAG_WORN then
					if IIfA.CharIdToName[ItemOwner] == nil then
						DBItem[ItemOwner] = nil
						n = n - 1
	  				end
				elseif ItemData.bagID == BAG_GUILDBANK then
					if IIfA.data.guildBanks[ItemOwner] == nil then
						DBItem[ItemOwner] = nil
						n = n - 1
					end
				end
			end
		end
		if (n == 0) then
			IIfA.database[ItemLink] = nil
		end
	end
-- 2015-3-7 end of addition
end


function IIfA:ClearLocationData(location, bagID)		-- if loc is characterid, bagID can be BAG_BACKPACK, or BAG_WORN, if nil, don't do anything
	local DBv3 = IIfA.database
	local itemLocation = nil
	local LocationCount = 0
	local itemName, itemData
	local bChar
	if bagID == nil then
		bChar = nil
	else
		bChar = location == IIfA.currentCharacterId
	end

	if(DBv3)then
		IIfA:DebugOut(zo_strformat("IIfA:ClearLocationData(<<1>>, <<2>>)", location, bagID))

		for itemName, itemData in pairs(DBv3) do
			itemLocation = itemData.locations[location]
			if itemLocation and (bChar == nil or (bChar and itemLocation.bagID == bagID)) then
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
--    elseif(hasDifferentQualities[itemType]) then
--        return string.format("%s,%s", itemId, data[4])
    else
        return itemId
    end
end

function IIfA:RenameItems()
	local DBv3 = IIfA.database
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


