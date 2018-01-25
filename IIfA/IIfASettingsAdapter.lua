 local IIfA = IIfA
 
 
function IIfA:IsCharacterInventoryIgnored(ignoreChar)
	return IIfA.data.ignoredCharEquipment[ignoreChar]
end

function IIfA:IsCharacterEquipIgnored(ignoreChar)
	return IIfA.data.ignoredCharInventories[ignoreChar]
end

function IIfA:IgnoreCharacterEquip(ignoreChar, value)
	IIfA.data.ignoredCharEquipment[ignoreChar] = value
	IIfA:ScanCurrentCharacter()
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