

local MAJOR, MINOR = "LibScroll", 1
local libScroll, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not libScroll then return end	--the same or newer version of this lib is already loaded into memory 

local ROW_TYPE_ID 			= 1
local DEFAULT_ROW_HEIGHT 	= 30
local DEFAULT_SCROLL_WIDTH 	= 250
local DEFAULT_SCROLL_HEIGHT = 400

-- Adds scroll list categories:
local function AddCategories(scrollList, categories)
	if not categories then return end
	
	for k,category in pairs(categories) do
		local categoryId = tonumber(category)
		if categoryId then
			-- not handling parent categories
			ZO_ScrollList_AddCategory(scrollList, categoryId, nil)
		end
	end
end

-- Used to get scroll list categories so they can be reloaded
-- after an Update. This is also used in case users manually add/remove
-- categories after the scrollList has been created & the original
-- categories may no longer be valid
local function GetListCategories(self)
	local categories = {}
	
	for categoryId in pairs(self.categories) do
		table.insert(categories, categoryId)
	end
	return categories
end

--[[ Must use deepTableCopy or it WILL crash if the user passes in a dataTable that is stored in saved variables. This is because ZO_ScrollList_CreateDataEntry creates a recursive reference to the data. Although this is only necessary for data saved in saved vars, I'm doing it to protect users against themselves
--]]
local function UpdateScrollList(scrollList, dataTable)
	local dataTableCopy = ZO_DeepTableCopy(dataTable)
	local dataList 		= ZO_ScrollList_GetDataList(scrollList)
	-- backup the current categories so we can reload them
	local currentCategories = GetListCategories(scrollList)
	
	ZO_ScrollList_Clear(scrollList)
	
	AddCategories(scrollList, currentCategories)
	
	-- Add data items to the list
	for k, dataItem in ipairs(dataTableCopy) do
		local entry = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, dataItem, dataItem.categoryId)
		table.insert(dataList, entry)
	end
	
	local sortFn = scrollList.SortFunction
	
	if sortFn then
		table.sort(dataList, sortFn)
	end
	
	ZO_ScrollList_Commit(scrollList)
end

--=======================================================--
--== Available Functions (by scrollList.reference) ==--
--=======================================================--
-- These are fairly simple even for a beginner 
-- are they worth putting in here?
--=======================================================--
local function ShowAllCategories(self)
	for k,catInfo in pairs(self.categories) do
		ZO_ScrollList_ShowCategory(self, catInfo.id)
	end
end
local function ShowOnlyCategory(self, categoryId)
	ZO_ScrollList_HideAllCategories(self)
	ZO_ScrollList_ShowCategory(self, categoryId)
end
local function ShowCategory(self, categoryId)
	ZO_ScrollList_ShowCategory(self, categoryId)
end
local function HideAllCategories(self)
	ZO_ScrollList_HideAllCategories(self)
end
local function HideCategory(self, categoryId)
	ZO_ScrollList_HideCategory(self, categoryId)
end
local function ClearList(self)
	ZO_ScrollList_Clear(self)
	ZO_ScrollList_Commit(self)
end

local function CreateScrollList(scrollData)
	local listName = scrollData.name
	local parent = scrollData.parent
	
	if not listName or type(listName) ~= "string" then return end
	if not parent then return end
	
	local listWidth = scrollData.width or DEFAULT_SCROLL_WIDTH
	local listheight = scrollData.height or DEFAULT_SCROLL_HEIGHT
	local rowHeight = scrollData.rowHeight or DEFAULT_ROW_HEIGHT
	local template = scrollData.rowTemplate or "ZO_SelectableLabel"
	local setupCallback = scrollData.setupCallback
	local selectCallback = scrollData.selectCallback
	-- Decided not to use a default or else it would force a highlight
	-- which some users may not want
	--local selectTemplate = scrollData.selectTemplate or "ZO_ThinListHighlight"
	local selectTemplate = scrollData.selectTemplate
	
	local scrollList = WINDOW_MANAGER:CreateControlFromVirtual(listName, parent, "ZO_ScrollList")
	
	if not scrollList then return end
	
	scrollList:SetDimensions(listWidth, listheight)
	
	ZO_ScrollList_AddDataType(scrollList, ROW_TYPE_ID, template, rowHeight, setupCallback, scrollData.hideCallback, scrollData.dataTypeSelectSound, scrollData.resetControlCallback)  
	
	if selectTemplate or selectCallback then
		ZO_ScrollList_EnableSelection(scrollList, selectTemplate, selectCallback)
	end
	
	AddCategories(scrollList, scrollData.categories)
	
	-- Easy Access References:
	scrollList.scrollData 		= scrollData
	scrollList.SortFunction 	= scrollData.sortFunction
	
	-- Easy Access Functions:
	scrollList.Clear				= ClearList
	scrollList.Update	 			= UpdateScrollList
	scrollList.ShowAllCategories	= ShowAllCategories
	scrollList.ShowOnlyCategory 	= ShowOnlyCategory
	scrollList.ShowCategory 		= ShowCategory
	scrollList.HideAllCategories 	= HideAllCategories
	scrollList.HideCategory			= HideCategory
	
	return scrollList
end

function libScroll:CreateScrollList(scrollData)
	if not scrollData then return end
	return CreateScrollList(scrollData)
end
