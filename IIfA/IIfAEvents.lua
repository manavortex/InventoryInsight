local IIfA 	= IIfA
local em 	= EVENT_MANAGER
-- 2016-7-26 AM - added global funcs for events
-- the following functions are all globals, not tied to the IIfA class, but call the IIfA class member functions for event processing

-- 2015-3-7 AssemblerManiac - added code to collect inventory data at char disconnect
local function IIfA_EventOnPlayerUnloaded()
	-- update the stored inventory every time character logs out, will assure it's always right when viewing from other chars
	IIfA:CollectAll()

	IIfA.CharCurrencyFrame:UpdateAssets()
	IIfA.CharBagFrame:UpdateAssets()
end


-- used by an event function
function IIfA:InventorySlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, qty)
	
	if isNewItem then
		isNewItem = "True"
	else
		isNewItem = "False"
	end

	local itemLink = GetItemLink(bagId, slotId, LINK_STYLE_BRACKETS) or ""
	if #itemLink == 0 then itemLink = (nil ~= IIfA.BagSlotInfo[bagId] and IIfA.BagSlotInfo[bagId][slotId]) end
	
	IIfA:DebugOut("Inv Slot Upd <<1>> - bag/slot <<2>>/<<3>> x<<4>>, new: <<6>>", 
		itemLink, bagId, slotId, qty, inventoryUpdateReason, tostring(isNewItem))
	
	-- (bagId, slotNum, fromXfer, itemCount, itemLink, itemName, locationID)
	local dbItem, itemKey = self:EvalBagItem(bagId, slotId, not isNewItem, qty, itemLink)
	
end


local function IIfA_InventorySlotUpdate(...)
	IIfA:InventorySlotUpdate(...)
end

local function IIfA_ScanHouse(eventCode, oldMode, newMode)
	if newMode == "showing" or newMode == "shown" then return end
	-- are we listening? 
	if not IIfA:GetCollectingHouseData() then return end
	local collectibleId = GetCollectibleIdForHouse(GetCurrentZoneHouseId())
	IIfA:DebugOut(zo_strformat("Housing editor mode is now <<2>> - calling IIfA:RescanHouse(<<1>>)", collectibleId, newMode))
	IIfA:RescanHouse(collectibleId)
end

local function IIfA_HouseEntered(eventCode)	
	if not IsOwnerOfCurrentHouse() then return end
	
	-- are we listening? 
	if not IIfA:GetCollectingHouseData() then return end
	
	-- is the house registered? 
	local houseCollectibleId = GetCollectibleIdForHouse(GetCurrentZoneHouseId())	
	
	if nil == IIfA.data.collectHouseData[houseCollectibleId] then
		IIfA:SetTrackingForHouse(houseCollectibleId, true)		
	end
	
	IIfA:RescanHouse(houseCollectibleId)
end
local function IIfA_EventProc(...)
	--d(...)
	local l = {...}
	local s = ""
	for name, data in pairs(l) do
		if type(data) ~= "table" then
			s = s .. name .. " = " .. tostring(data) .. "\r\n"
		else
			s = s .. name .. " = {" .. "\r\n"
			for name1, data1 in pairs(data) do
				if type(data1) ~= "table" then
					s = s .. "\t" .. name1 .. " = " .. tostring(data1) .. "\r\n"
				else
					s = s .. "\t" .. name1 .. " = {}" .. "\r\n"
				end
			end
			s = s .. "}\r\n"
		end
	end
	d(s)
end

local function finv1(...)
	d("inventory open error")
	IIfA_EventDump(...)
end
local function fgb1(...)
	d("gb open error")
	IIfA_EventDump(...)
end
local function fgb2(...)
	d("gb updated qty")
	IIfA_EventDump(...)
end
local function fgb3(...)
	d("gb selected")
	IIfA_EventDump(...)
end
local function fgb4(...)
	d("gb deselected")
	IIfA_EventDump(...)
end
local function fgb5(...)
	d("gb items ready")
	IIfA_EventDump(...)
end

function IIfA:RegisterForEvents()
	-- 2016-6-24 AM - commented this out, doing nothing at the moment, revisit later
	-- em:RegisterForEvent("IIFA_PLAYER_LOADED_EVENTS", EVENT_PLAYER_ACTIVATED, IIfA_EventOnPlayerloaded)

	-- 2015-3-7 AssemblerManiac - added EVENT_PLAYER_DEACTIVATED event
	em:RegisterForEvent("IIFA_PLAYER_UNLOADED_EVENTS", 	EVENT_PLAYER_DEACTIVATED, IIfA_EventOnPlayerUnloaded)

	-- when item comes into inventory
	em:RegisterForEvent( "IIFA_InventorySlotUpdate", 	EVENT_INVENTORY_SINGLE_SLOT_UPDATE, IIfA_InventorySlotUpdate)
	em:AddFilterForEvent("IIFA_InventorySlotUpdate", 	EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)

--	em:RegisterForEvent("IIFA_unknown", EVENT_ITEM_SLOT_CHANGED, IIfA_EventDump)
--	em:RegisterForEvent("IIFA_unknown", EVENT_INVENTORY_ITEM_USED, IIfA_EventDump)	-- arg 1 = event id, arg 2 = 27 (no clue)
--	em:RegisterForEvent("IIFA_unknown", EVENT_INVENTORY_ITEM_DESTROYED, IIfA_EventDump)
--	em:RegisterForEvent("IIFA_unknown", EVENT_JUSTICE_FENCE_UPDATE, IIfA_EventDump) -- # sold, # laundered is sent to event handler

-- not helpful, no link at all on this callback
--	SHARED_INVENTORY:RegisterCallback("SlotRemoved", IIfA_EventDump)
--	SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", IIfA_EventDump)
	
	
	-- Events for data collection
	em:RegisterForEvent("IIFA_ALPUSH", 		EVENT_ACTION_LAYER_PUSHED, 	function() IIfA:ActionLayerInventoryUpdate() end)
	em:RegisterForEvent("IIFA_BANK_OPEN",	EVENT_OPEN_BANK, 			function() IIfA:ScanBank() end)

	-- on opening guild bank:
	em:RegisterForEvent("IIFA_GUILDBANK_LOADED", EVENT_GUILD_BANK_ITEMS_READY, function() IIfA:GuildBankDelayReady() end)

--	em:RegisterForEvent("IIFA_gb1", EVENT_GUILD_BANK_OPEN_ERROR, fgb1)
	em:RegisterForEvent("IIFA_gb2", EVENT_GUILD_BANK_UPDATED_QUANTITY, fgb2)
--	em:RegisterForEvent("IIFA_gb3", EVENT_GUILD_BANK_SELECTED, fgb3)
--	em:RegisterForEvent("IIFA_gb4", EVENT_GUILD_BANK_DESELECTED, fgb4)
--	em:RegisterForEvent("IIFA_gb5", EVENT_GUILD_BANK_ITEMS_READY, fgb5)


	-- on adding or removing an item from the guild bank:
	em:RegisterForEvent("IIFA_GUILDBANK_ITEM_ADDED", 	EVENT_GUILD_BANK_ITEM_ADDED, 	function(...) IIfA:GuildBankAddRemove(...) end)
	em:RegisterForEvent("IIFA_GUILDBANK_ITEM_REMOVED", 	EVENT_GUILD_BANK_ITEM_REMOVED, 	function(...) IIfA:GuildBankAddRemove(...) end)

	-- Housing
	em:RegisterForEvent("IIFA_HOUSING_PLAYER_INFO_CHANGED", EVENT_PLAYER_ACTIVATED, 			IIfA_HouseEntered)	
	em:RegisterForEvent("IIfA_HOUSE_MANAGER_MODE_CHANGED", 	EVENT_HOUSING_EDITOR_MODE_CHANGED, 	IIfA_ScanHouse)

	em:RegisterForEvent("IIFA_GuildJoin",  EVENT_GUILD_SELF_JOINED_GUILD, 	function() IIfA:CreateOptionsMenu() end)
	em:RegisterForEvent("IIFA_GuildLeave", EVENT_GUILD_SELF_LEFT_GUILD, 	function() IIfA:CreateOptionsMenu() end)

	--    ZO_QuickSlot:RegisterForEvent(EVENT_ABILITY_COOLDOWN_UPDATED, IIfA_EventDump)	
	ZO_PreHook('ZO_InventorySlot_ShowContextMenu', function(rowControl) IIfA:ProcessRightClick(rowControl) end)
end


--[[ registerfilter & events
define HOW to listen for events (minimize # of calls to event handler, less overhead of eso internals)
em:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdate)
em:AddFilterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE,  REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
em:AddFilterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE,  REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
--]]


--[[ event for SHARED_INVENTORY:RegisterCallback sends as follows, and has no itemlink :(
arg 1 = 5		-- bag id
arg 2 = 71198		-- slot number
arg 3 = {
  inventory = {}
  condition = 100
  age = 6702.2509765625
  isPlaceableFurniture = false
  searchData = {}
  requiredLevel = 1
  stackCount = 1426
  stolen = false
  isPlayerLocked = false
  brandNew = true
  sellPrice = 2
  itemInstanceId = 3340100312
  statValue = 0
  rawName = rubedite ore
  locked = false
  isJunk = false
  stackSellPrice = 2852
  slotIndex = 71198
  specializedItemType = 0
  isBoPTradeable = false
  meetsUsageRequirement = true
  quality = 1
  filterData = {}
  equipType = 0
  name = Rubedite Ore
  itemType = 35
  bagId = 5
  stackLaunderPrice = 0
  uniqueId = 3.5176485852605e-319
  iconFile = /esoui/art/icons/crafting_jewelry_base_ruby_r1.dds
  launderPrice = 0
  }

--]]
