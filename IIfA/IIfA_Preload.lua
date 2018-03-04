 --this creates static strings

local strings = {
	IIFA_BAG_BAGPACK 	= "Inventory",
	IIFA_BAG_BANK 		= "Bank",
	IIFA_BAG_CRAFTBAG 	= "CraftBag",
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end

--[[ no longer needed
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
--]]
