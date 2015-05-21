IIfA = IIfA
-- 2015-3-10 AssemblerManiac - removed following delcaration, not used as a global as far as I can tell
-- local frame = IN2_INVENTORY_FRAME

function IIfA.getTableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function IIfA.DeleteCharacterData(name)
	if (name) then
		--delete selected character
		for characterName, character in pairs(IIfA.data.accountCharacters) do
			if(characterName == name) then
				IIfA.data.accountCharacters[name] = nil
			end
		end
	end
end

function IIfA.areTooltips()
	return IIfA.settings.in2ToggleDefaultTooltips
end

function IIfA.DeleteGuildData(name)
	if (name) then
		--delete selected guild
		for guildName, guild in pairs(IIfA.data.guildBanks) do
			if guildName == name then
				IIfA.data.guildBanks[name] = nil
			end
        end
	end
end

function IIfA.SetColour(...)
	IIfA.colourHandler:SetRGBA(...)
end

function IIfA.GetColour()
	return IIfA.colourHandler:UnpackRGBA()
end

function IIfA.GetDefaultFilter()
	return (IIfA.settings.in2DefaultInventoryFrameView) --  or "Bank And Characters"
end

function IIfA.GetColourHandler()
	if not IIfA.colourHandler then
		IIfA.colourHandler = ZO_ColorDef:New(IIfA.settings.in2TextColors)
	end
	return IIfA.colourHandler
end

function IIfA.GetTooltipFontSize()
	local ret			-- 2015-2-24 AssemblerManiac (found & reported by Harven at ESOUI)
	if IIfA.data then
		-- 2015-3-29 - AssemblerManiac - changed .data. to .settings.
		ret = IIfA.settings.in2TooltipsFontSize
	end
	return ret or 16
end


function IIfA.GetTooltipFont()
	local ret			-- 2015-2-24 AssemblerManiac (found & reported by Harven at ESOUI)
	if IIfA.data then
		-- 2015-3-29 - AssemblerManiac - changed .data. to .settings.
		ret = IIfA.settings.in2TooltipsFont
	end
	return ret or "ZoFontGame"
end

function IIfA.IN2_StatusAlert(message)
	if (IIfA.settings.in2Debug) then
		ZO_Alert(IIfA.defaultAlertType, IIfA.defaultAlertSound, message)
	end
end

function IIfA.IN2_DebugOutput(output)
	if (IIfA.settings.in2Debug) then
		d(output)
	end
end


function IIfA.GetNameForScene(scene)
	-- 2015-2-24 AssemblerManiac - made following IF more readable (instead of 2 lines, broke into more normal if/else format
	if scene == "tradinghouse" or scene == "trade" then
		return "trade"
	else
		return "inventory"
	end

end


function IIfA.ReadFrameSceneSettings(scene)

	local locked, minimized = false
	local x, y = 0
	local scenename = IIfA.GetNameForScene(scene)

	locked = IIfA.settings.in2InventoryFrameSceneSettings[scenename].locked
	minimized = IIfA.settings.in2InventoryFrameSceneSettings[scenename].minimized
	x = IIfA.settings.in2InventoryFrameSceneSettings[scenename].lastX
	y = IIfA.settings.in2InventoryFrameSceneSettings[scenename].lastY

	return locked, minimized, x, y

end

function IIfA.UpdateFrameSceneSettings(scene, newLocked,newMinimized, newX, newY)

	local scenename = IIfA.GetNameForScene(scene)

	if newLocked == nil then newLocked = false end
	if newMinimized == nil then newMinimized = false end
	if newX == nil then newX = 0 end
	if newY == nil then neyY = 0 end

	-- if IIfA.settings.in2InventoryFrameSceneSettings[scene] then -- if there's no preset for the scene, then there are nils all over the place
	IIfA.settings.in2InventoryFrameSceneSettings[scenename].locked = newLocked
	IIfA.settings.in2InventoryFrameSceneSettings[scenename].minimized = newMinimized
	IIfA.settings.in2InventoryFrameSceneSettings[scenename].lastX = newX
	IIfA.settings.in2InventoryFrameSceneSettings[scenename].lastY = newY
	-- end
end

function IIfA.AddToTooltip(tooltip, visibleList, numSlots, curSearch, curFilter)

	if nil == tooltip then return end
	if nil == visibleList then visibleList = "" end
	if nil == numSlots then numSlots = "" end
	if nil == curSearch then curSearch = "" end
	if nil == curFilter then curFilter = "" end

	tooltip:AddLine("Location: "..visibleList.."\nItems: "..numSlots.."\nCurrent Search: "..curSearch.."\nCurrent Filter: "..curFilter)

end


function IIfA.GetSceneVisible(name)
	if IIfA.settings.in2InventoryFrameScenes then
		return ( IIfA.settings.in2InventoryFrameScenes[name] and IIfA.settings.in2ShowInventoryFrame )
	else
		return true
	end
end

function IIfA.SetSceneVisible(name, value)
	IIfA.settings.in2InventoryFrameScenes[name] = value
end

function IIfA.toggleSceneVisibility(value)
			IIfA.settings.in2InventoryFrameScenes = {
			["bank"] = value,
			["guildBank"] =  value,
			["tradinghouse"] = value,
			["smithing"] = value,
			["store"] = value,
			["trade"] = value,
			["inventory"] = value
		}
end
