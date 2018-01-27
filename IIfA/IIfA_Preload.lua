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


function IIfA_SetButtonFilterText(control)
	local buttonIdxNames = {
		[1] = "All",
		[2] = "Weapons",
		[3] = "Armor", 
		[4] = "Consumables",
		[5] = "Materials",
		[6] = "Furniture", 
		[7] = "Miscellaneous",
	}
	local name = control:GetName() or ""
	local buttonIdx = control:GetName():gsub("IIFA_GUI_Header_Filter_Button", "") + 1
	control.filterText = buttonIdxNames[buttonIdx]
end