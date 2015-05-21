local IIfA = IIfA

function IIfA.IN2_RegisterForEvents()
	--
	EVENT_MANAGER:RegisterForEvent("IN2_PLAYER_LOADED_EVENTS", EVENT_PLAYER_ACTIVATED , IIfA.IN2_PlayerLoadedEvents)
	-- 2015-3-7 AssemblerManiac - added EVENT_PLAYER_DEACTIVATED event
	EVENT_MANAGER:RegisterForEvent("IN2_PLAYER_UNLOADED_EVENTS", EVENT_PLAYER_DEACTIVATED , IIfA.IN2_PlayerUnLoadedEvents)
	-- Events for data collection
--	EVENT_MANAGER:RegisterForEvent("IN2_ALPUSH", EVENT_ACTION_LAYER_PUSHED, IIfA.IN2_ActionLayerInventoryUpdate)
	-- on opening guild bank:
	EVENT_MANAGER:RegisterForEvent("IN2_GUILDBANK_LOADED", EVENT_GUILD_BANK_ITEMS_READY, IIfA.IN2_GuildBankDelayReady)
	-- on adding or removing an item from the guild bank:
	EVENT_MANAGER:RegisterForEvent("IN2_GUILDBANK_ITEM_ADDED", EVENT_GUILD_BANK_ITEM_ADDED, IIfA.IN2_GuildBankAddRemove)
	EVENT_MANAGER:RegisterForEvent("IN2_GUILDBANK_ITEM_REMOVED", EVENT_GUILD_BANK_ITEM_REMOVED, IIfA.IN2_GuildBankAddRemove)
	-- on inventory slot update:
	-- 2015-3-10 AssemblerManiac - removed unused event (no code in function, function also commented out)
	-- EVENT_MANAGER:RegisterForEvent("IN2_INVENTORY_ITEM_UPDATED",  EVENT_INVENTORY_SINGLE_SLOT_UPDATE, IIfA.IN2_ItemUpdate)
end

function IIfA.IN2_PlayerLoadedEvents()
	--Do these things only on the first load
	if(not IIfA.PlayerLoadedFired)then
		if(IIfA.data.in2AgedGuildBankDataWarning) then IIfA.IN2_CheckForAgedGuildBankData() end
		--Set PlayerLoadedFired = true to prevent future execution during this session
		IIfA.PlayerLoadedFired = true
	end
	--Do these things on any load
	--Do a little dance...
	--Make a little love...
	--Get down tonight...
end

-- 2015-3-7 - AssemblerManiac - added code to collect inventory data at char disconnect
function IIfA.IN2_PlayerUnLoadedEvents()
	-- update the stored inventory every time character logs out, will assure it's always right when viewing from other chars
	IIfA.CollectAll()
end
