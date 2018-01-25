 --this creates a menu for the addon.
local IIfA = IIfA

local strings = {
	IIFA_BAG_BAGPACK 	= "Inventar", 
	IIFA_BAG_BANK 		= "Bank", 
	IIFA_BAG_CRAFTBAG 	= "CraftBag", 
}


for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end