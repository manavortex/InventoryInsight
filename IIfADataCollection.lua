local IIfA = IIfA

function IIfA.CollectGuildBank()
	local DBv2 = IIfA.data.DBv2
	if(not DBv2)then
		IIfA.data.DBv2 = {}
		DBv2 = IIfA.data.DBv2
	end

--	d(IIfA.settings)

	if(IIfA.settings.in2ToggleGuildBankDataCollection) then

	IIfA.IN2_DebugOutput("Collecting Guild Bank Data")

	if not IIfA.data.guildBanks then IIfA.data.guildBanks = {} end
		local curGuild = GetGuildName(GetSelectedGuildBankId())
		local count = 0

		--fix: hardcoded the max guild bank slots to 500 for now, temporary fix
		local gbMaxSlots = 500;
		local guildData = IIfA.data.guildBanks[curGuild]
		if(guildData) then
			guildData.items = #ZO_GuildBankBackpack.data
			guildData.maxSlots = gbMaxSlots
		end
		IIfA.data.guildBanks[curGuild].lastCollected = GetDate().."@"..GetFormattedTime();
		IIfA.IN2_ResetLocationCount(curGuild)
		for i=1, #ZO_GuildBankBackpack.data do
			local slotIndex = ZO_GuildBankBackpack.data[i].data.slotIndex
			local itemName = GetItemName(BAG_GUILDBANK, slotIndex)
			if itemName > "" then
				local itemLink = GetItemLink(BAG_GUILDBANK, slotIndex, LINK_STYLE_BRACKETS)
				local itemKey = itemLink
				local usedInCraftingType, itemType, extraInfo1, extraInfo2, extraInfo3 = GetItemCraftingInfo(BAG_GUILDBANK, slotIndex)
				if usedInCraftingType ~= CRAFTING_TYPE_INVALID then
--					d(itemName)
--					d(itemName .. ", " .. itemType)
--					d(GetItemCraftingInfo(bag, item))
--					d(GetItemLinkItemType(itemLink))
					itemKey = IIfA.GetItemID(itemLink)
--					d(itemLink)
				else
					itemType = GetItemLinkItemType(itemLink)
					if itemType == ITEMTYPE_STYLE_MATERIAL or itemType == ITEMTYPE_ARMOR_TRAIT or itemType == ITEMTYPE_WEAPON_TRAIT or itemType == ITEMTYPE_LOCKPICK then
						itemKey = IIfA.GetItemID(itemLink)
					end
				end


				local itemFilterType = GetItemFilterTypeInfo(BAG_GUILDBANK, slotIndex) or 0
				local itemIconFile, _, _, _, _, _, _, itemQuality = GetItemInfo(BAG_GUILDBANK, slotIndex)
				local itemCount = ZO_GuildBankBackpack.data[i].data.stackCount
				local DBitem = DBv2[itemKey]
				local location = curGuild
				if(DBitem) then
					local DBitemlocation = DBitem[location]
					if(DBitemlocation) then
						DBitemlocation.itemCount = DBitem[location].itemCount + itemCount
	--					DBitemlocation.worn = false
					else
						DBitem[location] = {}
						DBitem[location].locationType = BAG_GUILDBANK
						DBitem[location].itemCount = itemCount
	--					DBitem[location].worn = false
					end
				else
					DBv2[itemKey] = {}
					DBv2[itemKey].attributes ={}
					DBv2[itemKey].attributes.iconFile = itemIconFile
					DBv2[itemKey].attributes.filterType = itemFilterType
					DBv2[itemKey].attributes.itemQuality = itemQuality
					DBv2[itemKey].attributes.itemName = itemName
					DBv2[itemKey][location] = {}
					DBv2[itemKey][location].locationType = BAG_GUILDBANK
					DBv2[itemKey][location].itemCount = itemCount
	--				DBv2[itemKey][location].worn = false
				end
				if zo_strlen(itemKey) < 10 then
					DBv2[itemKey].attributes.itemLink = itemLink
				end
			end
		end
	end
end

function IIfA.IN2_CheckForAgedGuildBankData( days )
	local results = false
	local days = days or 5
	if(IIfA.settings.in2ToggleGuildBankDataCollection) then
		IIfA.IN2_CleanEmptyGuildBug()
		for guildName, guildData in pairs(IIfA.data.guildBanks)do
			local today = GetDate()
			local lastCollected = guildData.lastCollected:match('(........)')
			if(lastCollected and lastCollected ~= "")then
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

function IIfA.IN2_UpdateGuildBankData()
	if(IIfA.settings.in2ToggleGuildBankDataCollection) then
		local tempGuildBankBag = {
			items = 0;
			lastCollected = "";
			maxSlots = 0;
		}
		for index=1, GetNumGuilds() do
			local guildName = GetGuildName(index)
			local guildData = IIfA.data.guildBanks[guildName]
			if(not guildData) then
				IIfA.data.guildBanks[guildName] = tempGuildBankBag
			end
		end
	end
end

function IIfA.IN2_CleanEmptyGuildBug()
	local emptyGuild = IIfA.data.guildBanks[""]
	if(emptyGuild)then
		IIfA.data.guildBanks[""] = nil
	end
end

function IIfA.IN2_GuildBankReady()
	IIfA.IN2_DebugOutput("GuildBankReady...")
	IIfA.GuildBankReady = false
	IIfA.IN2_UpdateGuildBankData()
	IIfA.IN2_CleanEmptyGuildBug()
	IIfA.CollectGuildBank()
end

function IIfA.IN2_GuildBankDelayReady()
	IIfA.IN2_DebugOutput("GuildBankDelayReady...")
--	d(IIfA.GuildBankReady)
	if not IIfA.GuildBankReady then
		IIfA.GuildBankReady = true
		zo_callLater(function() IIfA.IN2_GuildBankReady() end, 1500)
	end
end

function IIfA.IN2_GuildBankAddRemove()
	IIfA.IN2_DebugOutput("Guild Bank Add or Remove...")
	IIfA.IN2_UpdateGuildBankData()
	IIfA.IN2_CleanEmptyGuildBug()
	IIfA.CollectGuildBank()
end

-- 2015-3-10 AssemblerManiac - removed unused function
--[[
function IIfA.IN2_ItemUpdate()

end
--]]

--[[
local DBv2Prototype = {
	["itemLink"] = {
		filterType = 0,
		["locationName"] = {
			locationType = 0,
			itemCount = 0,
--			worn = false
		}
	}
}
]]


function IIfA.IN2_ActionLayerInventoryUpdate()
	IIfA.IN2_UpdateAccountCharacters()
	IIfA.CollectAll()
end

function IIfA.IN2_UpdateAccountCharacters()

	local character = IIfA.data.accountCharacters[GetUnitName( 'player' )]
	if(not character)then
		IIfA.data.accountCharacters[GetUnitName('player')] = {}
	end
end


--[[
Data collection notes:
	Currently crafting items are coming back from getitemlink with level info in them.
	If it's a crafting item, strip the level info and store only the item number.
	Use function GetItemCraftingInfo, if usedInCraftingType indicates it's NOT a material, check for other item types

	When showing items in tooltips, check for both stolen & owned, show both
--]]


function IIfA.CollectAll()
	local DBv2 = IIfA.data.DBv2
	if(not DBv2)then
		IIfA.data.DBv2 = {}
		DBv2 = IIfA.data.DBv2
	end

	local bagItems = nil
	local itemLink, itemName, itemFilterType, DBitem, DBitemlocation = nil
	local itemKey
	local location = ""

--	d("Bank Size=" .. GetBagSize(BAG_BANK))
--d("MaxBags: " .. GetMaxBags())
--	GetMaxBags returns 2, but bags are numbered from 0, so run one less
	for bag=0, GetMaxBags() + 1, 1 do
		bagItems = GetBagSize(bag)
--		d("Bag=" .. bag .. ", Size=" ..GetBagSize(bag))
		if(bag == BAG_WORN)then	--location for BAG_BACKPACK and BAG_WORN is the same so only reset once
			IIfA.IN2_ResetLocationCount(GetUnitName( 'player' ))
		elseif(bag == BAG_BANK)then
			IIfA.IN2_ResetLocationCount("Bank")
		end
		if( bag == BAG_BANK or bag == BAG_BACKPACK or bag == BAG_WORN) then
			for item=0, bagItems, 1 do
				itemName = GetItemName(bag, item)
				if itemName > '' then
					itemLink = GetItemLink(bag, item, LINK_STYLE_BRACKETS)
					itemKey = itemLink
					local usedInCraftingType, itemType, extraInfo1, extraInfo2, extraInfo3 = GetItemCraftingInfo(bag, item)
					if usedInCraftingType ~= CRAFTING_TYPE_INVALID then
--						d(itemName .. ", " .. itemType)
						itemKey = IIfA.GetItemID(itemLink)
--						d(itemLink)
					else
						itemType = GetItemLinkItemType(itemLink)
						if itemType == ITEMTYPE_STYLE_MATERIAL or itemType == ITEMTYPE_ARMOR_TRAIT or itemType == ITEMTYPE_WEAPON_TRAIT or itemType == ITEMTYPE_LOCKPICK then
							itemKey = IIfA.GetItemID(itemLink)
						end
					end

					local itemIconFile, itemCount, _, _, _, equipType, _, itemQuality = GetItemInfo(bag, item)
					itemFilterType = GetItemFilterTypeInfo(bag, item) or 0
					DBitem = DBv2[itemKey]
					location = ""
					if(equipType == 0 or bag ~= BAG_WORN) then equipType = false end
					if(bag == BAG_BACKPACK or bag == BAG_WORN)then
						location = GetUnitName( 'player' )
					elseif(bag == BAG_BANK)then
					 	location = "Bank"
					end
					if(DBitem) then
						DBitemlocation = DBitem[location]
						if DBitemlocation then
							DBitemlocation.itemCount = DBitemlocation.itemCount + itemCount
	--						DBitemlocation.worn = equipType
						else
							DBitem[location] = {}
							DBitem[location].locationType = bag
							DBitem[location].itemCount = itemCount
	--						DBitem[location].worn = equipType
						end
					else
						DBv2[itemKey] = {}
						DBv2[itemKey].attributes ={}
						DBv2[itemKey].attributes.iconFile = itemIconFile
						DBv2[itemKey].attributes.filterType = itemFilterType
						DBv2[itemKey].attributes.itemQuality = itemQuality
						DBv2[itemKey].attributes.itemName = itemName
						DBv2[itemKey][location] = {}
						DBv2[itemKey][location].locationType = bag
						DBv2[itemKey][location].itemCount = itemCount
	--					DBv2[itemKey][location].worn = equipType
					end
					if zo_strlen(itemKey) < 10 then
						DBv2[itemKey].attributes.itemLink = itemLink
					end
				end
			end
		end
	end

-- 2015-3-7 Assembler Maniac - new code added to go through full inventory list, remove any un-owned items
	local n
	for itemLink, DBItem in pairs(DBv2) do
		n = 0
		for ItemOwner, ItemData in pairs(DBItem) do
			n = n + 1
			if (not (ItemOwner == "Bank" or ItemOwner == "attributes")) then
				if (not IIfA.data.accountCharacters[ItemOwner]) then
					if (not IIfA.data.guildBanks[ItemOwner]) then
						DBItem[ItemOwner] = nil
					end
				end
			end
		end
		if (n == 1) then
			DBv2[itemLink] = nil
		end
	end
-- 2015-3-7 end of addition
--	d("Collect All Completed")
end


function IIfA.IN2_ResetLocationCount(location)
	local DBv2 = IIfA.data.DBv2
	local itemLocation = nil
	local LocationCount = 0

	if(DBv2)then
		for itemName, item in pairs(IIfA.data.DBv2 ) do
			itemLocation = item[location]
			if(itemLocation)then
				item[location] = nil
			end
			LocationCount = 0
			for locationName, location in pairs(item) do
				if(locationName ~= "filterType") then
					LocationCount = LocationCount + 1
					break
				end
			end
			if(LocationCount == 0)then
				DBv2[itemName] = nil
			end
		end
	end
end
