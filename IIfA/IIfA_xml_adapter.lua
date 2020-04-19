local IIfA = IIfA

function IIfA:GUILock(bLock)
	-- if we're docked, we can't very well lock it in place too
	-- this IF might go away providing the lock button turns on/off as it's supposed to (then it'll never be able to get here)
	if self:GetSceneSettings().docked then return end

	IIFA_GUI_Header_Locked:SetHidden(not bLock)
	IIFA_GUI_Header_Unlocked:SetHidden(bLock)

	self:GetSceneSettings().locked = bLock

	IIFA_GUI:SetMovable(not bLock)
	if bLock then
		IIFA_GUI:SetResizeHandleSize(0)
	else
		IIFA_GUI:SetResizeHandleSize(12)
	end
end

--[[
function IIfA:DisplayDockButton(settings, sceneName)

	if not sceneName then
		sceneName = IIfA:GetCurrentSceneName()
	end

	if not settings then
		settings = IIfA:GetSceneSettings(sceneName)
	end

	if sceneName == "hud" then
		IIFA_GUI_Header_Docked:SetHidden(true)
		IIFA_GUI_Header_Undocked:SetHidden(true)
	else
		IIFA_GUI_Header_Docked:SetHidden(not settings.docked)
		IIFA_GUI_Header_Undocked:SetHidden(settings.docked)
	end
end
 --]]

function IIfA:GuiDock(bDock)
	local sceneName = IIfA:GetCurrentSceneName()
	-- docking not allowed when hud is active (it has no clue what it's docking to)
	if bDock and sceneName == "hud" then
		return
	end

	local settings = IIfA:GetSceneSettings()

	settings.docked = bDock

	IIfA:RePositionFrame(settings)

--[[

	IIfA:DisplayDockButton(settings, nil)

	IIFA_GUI:ClearAnchors()
	IIFA_GUI:SetMovable(not bDock)
	--IIFA_GUI_Header_Lockedndson:SetHidden(bDock)
	--IIFA_GUI_Header_Unlocked:SetHidden(bDock)
	if bDock then
		-- two diff backgrouns on the right, figure out which is to be used
		local RightBackground = ZO_SharedRightPanelBackground
		if not ZO_SharedRightBackground:IsControlHidden() then
			RightBackground = ZO_SharedRightBackground
		end
		local parentHeight = RightBackground:GetHeight()
		IIFA_GUI:SetDimensionConstraints(410, parentHeight, -1, parentHeight)
		local windowOffset = -20
		if sceneName == "mailInbox" or sceneName == "mailSend" then
			windowOffset = -40
		end
		IIFA_GUI:SetAnchor(TOPRIGHT, RightBackground, TOPLEFT, windowOffset, 16)
		IIFA_GUI:SetAnchor(BOTTOMRIGHT, RightBackground, BOTTOMLEFT, windowOffset, 16)
		IIFA_GUI:SetResizeHandleSize(0)
		IIFA_GUI:SetWidth(settings.width)
		IIFA_GUI_Header_Unlocked:SetHidden(true)
		IIFA_GUI_Header_Locked:SetHidden(true)
	else
		IIFA_GUI:SetDimensionConstraints(410, 300, -1, 1400)
		IIFA_GUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settings.lastX, settings.lastY)
		if not settings.minimized then
			IIFA_GUI:SetHeight(settings.height)
			IIFA_GUI:SetWidth(settings.width)
			IIFA_GUI:SetResizeHandleSize(12)
		else
			IIFA_GUI:SetHeight(33)
			IIFA_GUI:SetWidth(settings.width)
			IIFA_GUI:SetResizeHandleSize(0)
		end
		self:GUILock(settings.locked)
	end

	IIfA:GuiResizeScroll()
	--]]
end

function IIfA:GUIMinimize(bMinimize)
	local settings = IIfA:GetSceneSettings()

	settings.minimized = bMinimize

	IIfA:RePositionFrame(settings)
--[[


	ZO_Tooltips_HideTextTooltip()
	IIFA_GUI_Header_Minimize:SetHidden(bMinimize)
	IIFA_GUI_Header_Maximize:SetHidden(not bMinimize)

	IIFA_GUI.minimized = bMinimize

	local settings = IIfA:GetSceneSettings()
	local lastX = IIFA_GUI:GetLeft()
	local lastY = IIFA_GUI:GetTop()

	settings.minimized = bMinimize

	if bMinimize then
		IIFA_GUI:SetResizeHandleSize(0)
		settings.width	= IIFA_GUI:GetWidth()
		settings.height = IIFA_GUI:GetHeight()
		IIFA_GUI:SetDimensionConstraints(410, 300, -1, 33)
		IIFA_GUI:SetHeight(33)
		PlaySound(SOUNDS.BACKPACK_WINDOW_CLOSE)
	else
		IIFA_GUI:SetResizeHandleSize(12)
		IIFA_GUI:SetDimensionConstraints(410, 300, -1, 1400)
		IIFA_GUI:SetHeight(settings.height)
		PlaySound(SOUNDS.BACKPACK_WINDOW_OPEN)
	end

	IIFA_GUI_ListHolder:SetHidden(bMinimize)
	IIFA_GUI_Header_Filter:SetHidden(bMinimize)
	IIFA_GUI_Header_Dropdown:SetHidden(bMinimize)
	IIFA_GUI_Search:SetHidden(bMinimize)
	IIFA_GUI_Header_GoldButton:SetHidden(bMinimize)
	IIFA_GUI_Header_SortBar:SetHidden(bMinimize)

	IIFA_GUI:ClearAnchors()
	IIFA_GUI:SetAnchor(TOPLEFT, nil, TOPLEFT, lastX, lastY)
	--]]
end

function IIfA:GUIButtonHideOnMouseUp()
	IIFA_GUI:SetHidden(true)
	local settings = IIfA:GetSceneSettings()
	settings.hidden = true
end

-- dropdown
--[[ no longer used
function IIfA:GuiSetupDropdown(dropdown)
	local selectedItem = IIfA:GetInventoryListFilter()
	dropdown.comboBox:SetSelectedItem(selectedItem)
	return true
end

function IIfA:GuiSetupQualityDropdown(dropdown)
	local selectedQuality = IIfA:GetInventoryListFilterQuality()
	local qualityDict = IIfA:getQualityDict()

	for choice, value in pairs(qualityDict) do
		if value == selectedQuality then
			dropdown.comboBox:SetSelectedItem(choice)
			break
		end
	end
end
--]]

-- click functions
function IIfA:GuiOnFilterButton(control, mouseButton, filterGroup, filterTypes, filterTypeNames)
	-- identify if this is main or sub filter clicked
	local ctrlName = control:GetName()

	local b_isMain = ctrlName:find("Sub") == nil

	if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and (ctrlName:sub(#ctrlName - 1, #ctrlName) == "10" or ctrlName:sub(#ctrlName, #ctrlName) ~= "0") then
		ctrlName = ctrlName:sub(1, #ctrlName - 1)
		if ctrlName:sub(#ctrlName, #ctrlName) == "1" then
			ctrlName = ctrlName:sub(1, #ctrlName - 1)
		end
		ctrlName = ctrlName .. "0"
		local myButton = WINDOW_MANAGER:GetControlByName(ctrlName, "")
		if myButton then
			local onMouseUpHandlerFunc = myButton:GetHandler("OnMouseUp")
			if onMouseUpHandlerFunc and type(onMouseUpHandlerFunc) == "function" then
 				onMouseUpHandlerFunc(myButton, nil)
				return
			end
		end
	end

	if b_isMain then
		if IIfA.LastFilterControl ~= nil then
			IIfA.LastFilterControl:SetState(BSTATE_NORMAL)
		end
		IIfA.LastFilterControl = control

		if IIfA.LastSubFilterControl ~= nil then
		   IIfA.LastSubFilterControl:SetState(BSTATE_NORMAL)
		   IIfA.LastSubFilterControl:GetParent():SetHidden(true)
		end
		if filterGroup ~= "All" then
			IIfA.LastSubFilterControl = IIFA_GUI_Header:GetNamedChild(control:GetName():gsub("IIFA_GUI_Header", IIfA.EMPTY_STRING):gsub("Filter_Button", "Subfilter_") .. "_Button0")
			IIfA.LastSubFilterControl:SetState(BSTATE_PRESSED)
		else
			IIfA.LastSubFilterControl = nil
		end
	else
		if IIfA.LastSubFilterControl ~= nil then
			IIfA.LastSubFilterControl:SetState(BSTATE_NORMAL)
			if IIfA.LastSubFilterControl:GetParent() ~= control:GetParent() then
				IIfA.LastSubFilterControl:GetParent():SetHidden(true)
			end
		end
		IIfA.LastSubFilterControl = control
	end

	control:SetState(BSTATE_PRESSED)

	if IIfA.LastSubFilterControl == nil then
		IIFA_GUI_Header_Subfilter:SetHidden(true)
		IIFA_GUI_Header_Subfilter:SetHeight(10)
	else
		IIFA_GUI_Header_Subfilter:SetHidden(false)
		IIFA_GUI_Header_Subfilter:SetHeight(38)
		local SubFilt = IIfA.LastSubFilterControl:GetParent()
		SubFilt:SetHidden(false)
		SubFilt:SetHeight(38)
	end
	IIfA.filterGroup = filterGroup
	IIfA.filterTypes = filterTypes

	local function SetSubSubFilters(_, subFiltName, choice)
		IIfA.filterTypes = choice.subFiltTypes
		IIfA:RefreshInventoryScroll()
	end

	if filterTypeNames ~= nil then
		local comboBox
		if IIFA_GUI_Header_SortBar_Subfilter_Dropdown.comboBox ~= nil then
			comboBox = IIFA_GUI_Header_SortBar_Subfilter_Dropdown.comboBox
		else
			comboBox = ZO_ComboBox_ObjectFromContainer(IIFA_GUI_Header_SortBar_Subfilter_Dropdown)
			IIFA_GUI_Header_SortBar_Subfilter_Dropdown.comboBox = comboBox
		end
		comboBox:ClearItems()
		comboBox:SetSortsItems(false)
		local entry = comboBox:CreateItemEntry("All", SetSubSubFilters)
		entry.subFiltTypes = IIfA.filterTypes
		comboBox:AddItem(entry)
		if IIfA.filterGroup == "Body" or		--:find("Body") ~= nil or
		   IIfA.filterGroup == "Specialized" then
			for i = 2, #filterTypes do
				entry = comboBox:CreateItemEntry(filterTypeNames[i], SetSubSubFilters)
				entry.subFiltTypes = { filterTypes[1], filterTypes[i] }
				comboBox:AddItem(entry)
			end
		else
			for i = 1, #filterTypes do
				entry = comboBox:CreateItemEntry(filterTypeNames[i], SetSubSubFilters)
				entry.subFiltTypes = { filterTypes[i] }
				comboBox:AddItem(entry)
			end
		end
		comboBox:SetSelectedItem("All")
		IIFA_GUI_Header_SortBar_Subfilter_Dropdown:SetHidden(false)
	else
		IIFA_GUI_Header_SortBar_Subfilter_Dropdown:SetHidden(true)
	end


	IIfA:GuiResizeScroll()

	IIfA:RefreshInventoryScroll()
end

-- IIfA.GUI_SearchBox is the input field
-- IIfA.GUI_SearchBoxText is the "Filter by text search" text msg
function IIfA:GuiOnSearchboxText(control)
	local text = control:GetText()
	IIfA:ApplySearchText(text)
end

function IIfA:ApplySearchText(text)
--d("IIfA:ApplySearchText - text: " .. tostring(text))
    --Search and update the list
    local function updateSearchTextFilterAndDoSearch(p_searchText)
		local countFound = 0
        if p_searchText then
            IIfA.searchFilter = p_searchText
            -->This function refreshes AND filters the dataLines of the list IIFA_GUI_ListHolder, within UpdateScrollDataLinesData()
			IIfA:RefreshInventoryScroll()
			if IIFA_GUI_ListHolder.dataLines then
				countFound = #IIFA_GUI_ListHolder.dataLines
			end
        end
		return countFound
    end
	--Function to strip the article of a text in some client languages, e.g. de (der, die, das) or french (le, la, les)
	local function stripArticlePrefix(textToStripFrom)
		if not textToStripFrom then return false, nil end
		local articelStripped = false
		local articlesOfLanguage = {
			["de"] = {["der"] = true, ["die"] = true, ["das"] = true},
			["fr"] = {["le"] = true, ["la"] = true, ["les"] = true},
		}
		local lang = IIfA.clientLanguage or GetCVar("language.2")
		if not articlesOfLanguage[lang] then return false, nil end
		local textWithoutArticle
		--Any whitespaces in the text?
		local firstWhiteSpaceIndex = string.find(textToStripFrom, "%s")
--d(">firstWhiteSpaceIndex: " ..tostring(firstWhiteSpaceIndex))
		if firstWhiteSpaceIndex ~= nil then
			--Get the text before the first whitespace
			local possibleArticleText = string.sub(textToStripFrom, 1, firstWhiteSpaceIndex)
--d(">possibleArticleText: " ..tostring(possibleArticleText))
			if articlesOfLanguage[lang][possibleArticleText] then
				articelStripped = true
				textWithoutArticle = string.sub(textToStripFrom, firstWhiteSpaceIndex+1)
			end
		end
		return articelStripped, textWithoutArticle
	end

    IIfA.GUI_SearchBoxText:SetHidden(text ~= nil and text > IIfA.EMPTY_STRING)

	local searchTextLower = zo_strlower(text)
    local foundCount = updateSearchTextFilterAndDoSearch(searchTextLower)
--d(">text 1st searched: " ..tostring(searchTextLower) .. ", found: " ..tostring(foundCount))

    --Nothing was found but we called the search from our own inventory (there must be at least 1hit then!):
    --Try to search with the article removed, if the client language uses gender specific string suffix on the nams like ^mx or ^fs
    if IIfA.clientLanguageUsesGenderString == true then
		if foundCount == 0 then
			local textClean = ZO_CachedStrFormat("<<C:1>>", searchTextLower)
			if textClean and textClean > IIfA.EMPTY_STRING then
				--Is the search text starting with an article of the current client language
				local articleStripped, textCleanWithouArticle = stripArticlePrefix(textClean)
--d(">articleStripped: " ..tostring(articleStripped) .. ", textCleanWithouArticle: " ..tostring(textCleanWithouArticle))
				if not articleStripped or not textCleanWithouArticle or textCleanWithouArticle == searchTextLower or textCleanWithouArticle == IIfA.EMPTY_STRING then return end
				--Nothing was found. Remove the leading article (text until first space) from the search term and try again
				textCleanWithouArticle = zo_strlower(textCleanWithouArticle)
				updateSearchTextFilterAndDoSearch(textCleanWithouArticle)
--d(">text 2nd searched: " ..tostring(textCleanWithouArticle))
			end
        end
    end
end

function IIfA:GuiOnSearchBoxClear(control)
	IIfA.GUI_SearchBox:SetText(IIfA.EMPTY_STRING)
	IIfA.GUI_SearchBoxText:SetHidden(false)
	IIfA.searchFilter = IIfA.EMPTY_STRING
	IIfA:RefreshInventoryScroll()
end



	-- We're inverting search order if same header is clicked twice.
IIfA.bSortQuality = false
-- IIFA_GUI_ListHolder sort
function IIfA:GuiOnSort(sortQuality)

	if (IIfA.bSortQuality == sortQuality) then
		IIfA.ScrollSortUp = not IIfA.ScrollSortUp
	end
	IIfA.bSortQuality = sortQuality

	local icon = IIFA_GUI_Header_SortBar.Icon

	if (IIfA.ScrollSortUp) then
		icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds")
		icon:SetAlpha(1)
	else
		icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds")
		icon:SetAlpha(1)
	end
	IIfA:RefreshInventoryScroll()
end

function IIfA:GuiOnScroll(control, delta)
--	IIfA:DebugOut("guionscroll called")

	if not delta then return end
	if delta == 0 then return end

	local slider = IIFA_GUI_ListHolder_Slider
--	slider.locked = true
	-- negative delta means scrolling down

	local value = (IIFA_GUI_ListHolder.dataOffset - delta)
	local total = #IIFA_GUI_ListHolder.dataLines - IIFA_GUI_ListHolder.maxLines

	if value < 0 then value = 0 end
	if value > total then value = total end
	IIFA_GUI_ListHolder.dataOffset  = value

	IIfA:UpdateInventoryScroll()

	slider:SetValue(IIFA_GUI_ListHolder.dataOffset)

	IIfA:GuiLineOnMouseEnter(moc())
	--IIfA:UpdateTooltip(IIFA_ITEM_TOOLTIP, true)


--	slider.locked = false
end

-- IIFA_GUI_ListHolder.lines
function IIfA:GuiLineOnMouseEnter(lineControl)
	if not lineControl then return end

	if( lineControl.itemLink ~= nil and lineControl.itemLink ~= IIfA.EMPTY_STRING) then
		IIfA.TooltipLink = lineControl.itemLink
		InitializeTooltip(ItemTooltip, lineControl, LEFT, 0, 0, 0)
		ItemTooltip:SetLink(lineControl.itemLink)
--		IIfA:UpdateTooltip(IIFA_ITEM_TOOLTIP)
	end
end

function IIfA:GuiLineOnMouseExit(control)
	ClearTooltip(ItemTooltip)
end


function IIfA:GuiOnSliderUpdate(slider, value)
	if not value or slider.locked then return end
	local relativeValue = math.floor(IIFA_GUI_ListHolder.dataOffset - value)
	IIfA:GuiOnScroll(slider, relativeValue)
end

function IIfA:GuiResizeScroll()		-- returns true if it had to be resized, otherwise false
	if IIFA_GUI.minimized then return end		-- no point trying to resize if there's no scroll bar displayed

	local regionHeight = IIFA_GUI_ListHolder:GetHeight()
	local newLines = math.floor(regionHeight / IIFA_GUI_ListHolder.rowHeight)

	if IIFA_GUI_ListHolder.maxLines == nil or IIFA_GUI_ListHolder.maxLines ~= newLines then
		IIFA_GUI_ListHolder.maxLines = newLines
		IIfA:GuiResizeLines()
	end
end

function IIfA:GuiShowTooltip(control, tooltiptext)
	InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0, 0)
	InformationTooltip:SetHidden(false)
	InformationTooltip:ClearLines()
	InformationTooltip:AddLine(tooltiptext)
end

function IIfA:GuiShowFilterTooltip(control, tooltiptext)
	InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0, 0)
	InformationTooltip:SetHidden(false)
	InformationTooltip:ClearLines()
	InformationTooltip:AddLine(tooltiptext)
end

function IIfA:GuiHideTooltip(control)
	InformationTooltip:SetHidden(true)
	InformationTooltip:ClearLines()
end

-- resize to saved settings
function IIfA:GuiReloadDimensions(settings, sceneName)

	if not settings then
		settings = IIfA:GetSceneSettings(sceneName)
	end

	IIfA:DisplayDockButton(settings, sceneName)

	if not settings.docked then
		if settings.minimized then
			IIFA_GUI:SetHeight(33)
		else
			IIFA_GUI:SetHeight(settings.height)
		end
	end
	IIfA:GuiResizeScroll()
	IIFA_GUI:SetWidth(settings.width)
end

function IIfA:GuiResizeLines()
	local lines

	if not IIFA_GUI_ListHolder.lines then
		lines = IIfA:CreateInventoryScroll()
	end
	if IIFA_GUI_ListHolder.lines ~= {} then
		lines = IIFA_GUI_ListHolder.lines
	end

--	local linewidth =  (IIFA_GUI_ListHolder:GetWidth()-20)
--	local qtywidth = lines[1].qty:GetWidth()
--	local iconwidth = lines[1].icon:GetWidth()
--	local textwidth = linewidth - qtywidth - iconwidth

	for index, line in ipairs(lines) do
--		line.text:SetWidth(textwidth)
--		line:SetWidth(linewidth)
		line:SetHidden(index > IIFA_GUI_ListHolder.maxLines)
	end
end

function IIfA:onResizeStart()
	EVENT_MANAGER:RegisterForUpdate(IIfA.name.."OnWindowResize", 50,function() IIfA:GuiResizeScroll() if not IIfA:GetSceneSettings().docked then
		IIfA:UpdateInventoryScroll()
	end end)
end

function IIfA:onResizeStop()
	-- if you resize the box, you need to resize the list to go with it
	-- local sceneName = IIfA:GetCurrentSceneName()
	EVENT_MANAGER:UnregisterForUpdate(IIfA.name.."OnWindowResize")
	local settings = IIfA:GetSceneSettings()

	IIfA:SaveFrameInfo("onResizeStop")

	IIfA:GuiResizeScroll()
	if not settings.docked then
		IIfA:UpdateInventoryScroll()
	end
end

-- put separate dock/minimize/restore sizing code into unified function so all resizing gets done in one place, one time
function IIfA:RePositionFrame(settings)
	--[[
	re-position frame based on current settings
	- docked - no sizing handles, no moving, anchor to left edge of conrols on right side of screen, width at minimum, height determined by right hand control
	- locked - no sizing handles, no moving, anchor to GUIRoot, pos/size based on last known info
	- minimized - no sizing handles, anchor to GUIRoot, height 33, width at minimum, pos based on last known info
	- hidden - just hide the whole works as is
	- none of the above, sizing handles 12, anchor to GUIRoot, pos/size based on last known info
	--]]


	ZO_Tooltips_HideTextTooltip()
	local sceneName = IIfA:GetCurrentSceneName()
	if settings == nil then
		settings = IIfA:GetSceneSettings()
	end

--	IIfA:DebugOut("Reposition Frame")
--	IIfA:DebugOut(settings)

-- revisit - also look at toggleinventoryframe (it *should* be doing more than just show when it's not vis, like re-applying everything)
--	if settings.hidden == true and IIFA_GUI:IsHidden() then
--		return
--	end

	local bIsHud = (sceneName == "hud")

	local bMinimize = settings.minimized

	-- all of these go away if we're minimizing, otherwise they're shown
	IIFA_GUI_ListHolder:SetHidden(bMinimize)
	IIFA_GUI_Header_Filter:SetHidden(bMinimize)
	if IIfA.LastSubFilterControl == nil or bMinimize then
		IIFA_GUI_Header_Subfilter:SetHidden(true)
		IIFA_GUI_Header_Subfilter:SetHeight(0)
	else
		IIFA_GUI_Header_Subfilter:SetHidden(false)
		IIFA_GUI_Header_Subfilter:SetHeight(38)
	end
	IIFA_GUI_Header_Dropdown_Main:SetHidden(bMinimize)
	IIFA_GUI_Header_Dropdown_Quality:SetHidden(bMinimize)
	IIFA_GUI_Search:SetHidden(bMinimize)
	IIFA_GUI_Header_GoldButton:SetHidden(bMinimize)
	IIFA_GUI_Header_BagButton:SetHidden(bMinimize)
	IIFA_GUI_Header_SortBar:SetHidden(bMinimize)

	IIFA_GUI:ClearAnchors()
	if bMinimize then
		IIFA_GUI:SetResizeHandleSize(0)
		-- have to change the constraints, it even constrains resizing by code, not just resize by sizing handles
   		IIFA_GUI:SetDimensionConstraints(IIfA.minWidth, 44, -1, 1400)

		IIFA_GUI:SetHeight(33)
		IIFA_GUI:SetWidth(settings.width)
		IIFA_GUI:SetAnchor(TOPLEFT, GUIRoot, TOPLEFT, settings.lastX, settings.lastY)

		-- no docking while minimized
		IIFA_GUI_Header_Docked:SetHidden(true)
		IIFA_GUI_Header_Undocked:SetHidden(true)

		-- flip the min/max buttons
		IIFA_GUI_Header_Minimize:SetHidden(true)
		IIFA_GUI_Header_Maximize:SetHidden(false)
	else
   		IIFA_GUI:SetDimensionConstraints(IIfA.minWidth, 300, -1, 1400)
--		IIfA:SetInventoryListFilterQuality(IIfA:GetInventoryListFilterQuality())

		if settings.docked then
			-- no resizing handles
			IIFA_GUI:SetResizeHandleSize(0)

			-- no min/max buttons
			IIFA_GUI_Header_Minimize:SetHidden(true)
			IIFA_GUI_Header_Maximize:SetHidden(true)

			-- no lock/unlock buttons
			IIFA_GUI_Header_Locked:SetHidden(true)
			IIFA_GUI_Header_Unlocked:SetHidden(true)
			IIFA_GUI:SetMovable(false)

			-- set docked buttons properly
			IIFA_GUI_Header_Docked:SetHidden(false)
			IIFA_GUI_Header_Undocked:SetHidden(true)

			local RightBackground = ZO_SharedRightPanelBackground
			if not ZO_SharedRightBackground:IsControlHidden() then
				RightBackground = ZO_SharedRightBackground
			end
			local parentHeight = RightBackground:GetHeight()
			local windowOffset = -20
			if sceneName == "mailInbox" or sceneName == "mailSend" then
				windowOffset = -40
			end
			IIFA_GUI:SetHeight(parentheight)
			IIFA_GUI:SetWidth(self.minWidth)
			IIFA_GUI:SetAnchor(TOPRIGHT, RightBackground, TOPLEFT, windowOffset, 16)
			IIFA_GUI:SetAnchor(BOTTOMRIGHT, RightBackground, BOTTOMLEFT, windowOffset, 16)
		else
			IIFA_GUI:SetHeight(settings.height)
			IIFA_GUI:SetWidth(settings.width)
			if not settings.locked then
				IIFA_GUI:SetResizeHandleSize(12)
			else
				IIFA_GUI:SetResizeHandleSize(0)
			end

			-- set the min/max buttons
			IIFA_GUI_Header_Minimize:SetHidden(false)
			IIFA_GUI_Header_Maximize:SetHidden(true)

			-- display lock/unlock buttons
			IIFA_GUI_Header_Locked:SetHidden(not settings.locked)
			IIFA_GUI_Header_Unlocked:SetHidden(settings.locked)
			IIFA_GUI:SetMovable(not settings.locked)

			-- set docked buttons properly
			IIFA_GUI_Header_Docked:SetHidden(true)
			IIFA_GUI_Header_Undocked:SetHidden(bIsHud)

			-- different anchor point
			IIFA_GUI:SetAnchor(TOPLEFT, GUIRoot, TOPLEFT, settings.lastX, settings.lastY)
		end
	end

	if not settings.hidden then
		IIfA:GuiResizeScroll()
		IIfA:RefreshInventoryScroll()

	end
	IIFA_GUI:SetHidden(settings.hidden)
end



function IIfA:SetNameFilterToggle()
	IIfA:SetSetNameFilterOnly(not IIfA.bFilterOnSetName)
end
