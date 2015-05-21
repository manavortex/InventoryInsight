
local IIfA = IIfA

function IIfA.CollectGuildBank()
--function IIfA.CollectGuildBankV2()
	local DBv2 = IIfA.data.DBv2
	if(not DBv2)then 
		IIfA.data.DBv2 = {} 
		DBv2 = IIfA.data.DBv2
	end
	if(IIfA.data.in2ToggleGuildBankDataCollection) then
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
			slotIndex=ZO_GuildBankBackpack.data[i].data.slotIndex
			local itemLink = GetItemLink(BAG_GUILDBANK, slotIndex, LINK_STYLE_BRACKETS)
			local itemName = GetItemName(BAG_GUILDBANK, slotIndex)
			local itemFilterType = GetItemFilterTypeInfo(BAG_GUILDBANK, slotIndex) or 0
			local itemIconFile, _, _, _, _, _, _, itemQuality = GetItemInfo(BAG_GUILDBANK, slotIndex)
			local itemCount = ZO_GuildBankBackpack.data[i].data.stackCount
			local DBitem = DBv2[itemLink]
			local location = curGuild
			if(DBitem) then
				local DBitemlocation = DBitem[location]
				if(DBitemlocation) then
					DBitemlocation.itemCount = itemCount
					DBitemlocation.worn = false
				else
					DBitem[location] = {}
					DBitem[location].locationType = BAG_GUILDBANK
					DBitem[location].itemCount = itemCount
					DBitem[location].worn = false
				end
			else
				DBv2[itemLink] = {}
				DBv2[itemLink].attributes ={}
				DBv2[itemLink].attributes.iconFile = itemIconFile
				DBv2[itemLink].attributes.filterType = itemFilterType
				DBv2[itemLink].attributes.itemQuality = itemQuality
				DBv2[itemLink].attributes.itemName = itemName
				DBv2[itemLink][location] = {}
				DBv2[itemLink][location].locationType = BAG_GUILDBANK
				DBv2[itemLink][location].itemCount = itemCount
				DBv2[itemLink][location].worn = false
			end
		end
	end
end

function IIfA.IN2_CheckForAgedGuildBankData( days )
	local results = false
	local days = days or 5
	if(IIfA.data.in2ToggleGuildBankDataCollection) then
		IIfA.IN2_CleanEmptyGuildBug()
		for guildName, guildData in pairs(IIfA.data.guildBanks)do
			local today = GetDate()				
			local lastCollected = guildData.lastCollected:match('(........)')
			if(lastCollected and lastCollected ~= "")then
				if(today - lastCollected >= days)then
					d("[IIfA]:Warning - "..guildName.." Guild Bank data not collected in "..days.." or more days!")
					results = true
				end
			else
				d("[IIfA]:Warning - "..guildName.." Guild Bank data has not been collected!")
				results = true
			end
		end
		return results
	end
	return true
end

function IIfA.IN2_UpdateGuildBankData()
	if(IIfA.data.in2ToggleGuildBankDataCollection) then
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

function IIfA.IN2_GuildBankActions()
	IIfA.IN2_DebugOutput("GuildBankProcessed...")
	IIfA.IN2_UpdateGuildBankData()
	IIfA.IN2_CleanEmptyGuildBug()
	IIfA.CollectGuildBank()
end

function IIfA.IN2_ItemUpdate()


end

--[[
local DBv2Prototype = {
	["itemLink"] = {
		filterType = 0,
		["locationName"] = {
			locationType = 0,
			itemCount = 0,
			worn = false
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


function IIfA.CollectAll()
--function IIfA.CollectAllV2()
	local DBv2 = IIfA.data.DBv2
	if(not DBv2)then 
		IIfA.data.DBv2 = {} 
		DBv2 = IIfA.data.DBv2
	end
	
	local bagItems = nil;
	local itemLink, itemName, itemFilterType, DBitem, DBitemlocation = nil
	local location = ""
	
	for bag=0, GetMaxBags(), 1 do
		bagItems = GetBagSize and GetBagSize(bag) or select(2, GetBagInfo(bag))
		if(bag == BAG_WORN)then	--location for BAG_BACKPACK and BAG_WORN is the same son only reset once
			IIfA.IN2_ResetLocationCount(GetUnitName( 'player' ))
		elseif(bag == BAG_BANK)then
			IIfA.IN2_ResetLocationCount("Bank")
		end
		if( bag == BAG_BANK or bag == BAG_BACKPACK or bag == BAG_WORN) then
			for item=0, bagItems, 1 do	
				itemLink = GetItemLink(bag, item, LINK_STYLE_BRACKETS)
				itemName = GetItemName(bag, item)
				local itemIconFile, itemCount, _, _, _, equipType, _, itemQuality = GetItemInfo(bag, item)
				itemFilterType = GetItemFilterTypeInfo(bag, item) or 0
				DBitem = DBv2[itemLink]
				location = ""
				if(equipType == 0 or bag ~= BAG_WORN) then equipType = false end
				if(bag == BAG_BACKPACK or bag == BAG_WORN)then
					location = GetUnitName( 'player' )
				elseif(bag == BAG_BANK)then
				 	location = "Bank"
				end
				if(DBitem) then
					DBitemlocation = DBitem[location]
					if(DBitemlocation) then
						DBitemlocation.itemCount = DBitemlocation.itemCount + itemCount
						DBitemlocation.worn = equipType
					else
						DBitem[location] = {}
						DBitem[location].locationType = bag
						DBitem[location].itemCount = itemCount
						DBitem[location].worn = equipType
					end
				else
					DBv2[itemLink] = {}
					DBv2[itemLink].attributes ={}
					DBv2[itemLink].attributes.iconFile = itemIconFile
					DBv2[itemLink].attributes.filterType = itemFilterType
					DBv2[itemLink].attributes.itemQuality = itemQuality
					DBv2[itemLink].attributes.itemName = itemName
					DBv2[itemLink][location] = {}
					DBv2[itemLink][location].locationType = bag
					DBv2[itemLink][location].itemCount = itemCount
					DBv2[itemLink][location].worn = equipType
				end
			end
		end
	end
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
				end		
			end
			if(LocationCount == 0)then
				DBv2[itemName] = nil
			end
		end
	end
end