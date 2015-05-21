local IIfA = IIfA

local LMP = LibStub("LibMediaProvider-1.0")
local IN2_SORT_OFF = 0
local IN2_SORT_DOWN = 1
local IN2_SORT_UP = 2

IN2_INVENTORY_FRAME = nil
IN2_INVENTORY_FRAME_SCROLL = nil
IN2_INVENTORY_DROPDOWN_CONTROL = nil
IN2_INVENTORY_SEARCHBOX_CONTROL = nil
IN2_CURRENTLY_VISIBLE_INVENTORY_LIST = "All"

-- 2015-3-30 AssemblerManiac - removed duplicate declaration
-- IIfA.InventoryFrame_SortOrder = IN2_SORT_OFF

-- 2015-3-30 Assembler Maniac - renamed sortBy... to filterby (since it is a filter, not a sorting order, also makes it easier to find related items since there is already a sort option elsewhere
-- 2015-3-30 continued - also renamed all items related to the filter
IIfA.filterByEquipTypes = {
	[ITEMFILTERTYPE_ALL]			=   { enabledEquipType = "/esoui/art/inventory/inventory_tabicon_all_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_all_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_all_over.dds"},
	[ITEMFILTERTYPE_WEAPONS]		=   { enabledEquipType = "/esoui/art/inventory/inventory_tabicon_weapons_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_weapons_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_weapons_over.dds"},
	[ITEMFILTERTYPE_ARMOR]			=   { enabledEquipType = "/esoui/art/inventory/inventory_tabicon_armor_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_armor_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_armor_over.dds"},
	[ITEMFILTERTYPE_CONSUMABLE]		=   { enabledEquipType = "/esoui/art/inventory/inventory_tabicon_consumables_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_consumables_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_consumables_over.dds"},
	[ITEMFILTERTYPE_CRAFTING]		=	{ enabledEquipType = "/esoui/art/inventory/inventory_tabicon_crafting_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_crafting_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_crafting_over.dds"},
	[ITEMFILTERTYPE_MISCELLANEOUS]	=   { enabledEquipType = "/esoui/art/inventory/inventory_tabicon_misc_up.dds", disabledEquipType = "/esoui/art/inventory/inventory_tabicon_misc_disabled.dds", mouseOverEquipType = "/esoui/art/inventory/inventory_tabicon_misc_over.dds"}
}

IIfA.filterByEquipTypesStrings = {
	[ITEMFILTERTYPE_ALL]  = "All",
	[ITEMFILTERTYPE_WEAPONS]  = "Weapons",
	[ITEMFILTERTYPE_ARMOR]  =  "Armor",
	[ITEMFILTERTYPE_CONSUMABLE]  = "Consumables",
	[ITEMFILTERTYPE_CRAFTING]  = "Crafting",
	[ITEMFILTERTYPE_MISCELLANEOUS]  = "Miscellaneous"
}

--[[----------------------------------------------------------------------]]

function IIfA.IN2_UpdateScrollDataLinesData( searchFilter )
--function IIfA.IN2_UpdateScrollDataLinesDataV2( searchFilter )
	local index = 0
	local in2scroll = IN2_INVENTORY_FRAME_SCROLL
	in2scroll.DataLines = {}
	local DataLines = in2scroll.DataLines
	local DBv2 = IIfA.data.DBv2
	local iLink, itemLink, itemName, iconFile, itemQuality, tempDataLine = nil
	local itemTypeFilter, itemCount = 0
	if(DBv2)then
		for itemLink, item in pairs(IIfA.data.DBv2) do
			if zo_strlen(itemLink) < 10 then
				iLink = item.attributes.itemLink
			else
				iLink = itemLink
			end
			if (itemLink ~= "") then
				itemName = item.attributes.itemName
				iconFile = item.attributes.iconFile
				itemTypeFilter = 0
				if(item.attributes.filterType)then
					itemTypeFilter = item.attributes.filterType
				end
				itemQuality = item.attributes.itemQuality
				itemCount = 0
				for locationName, location in pairs(item) do
					if(locationName ~= "attributes")  then
						if(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "All") then
							itemCount = itemCount + location.itemCount
						elseif(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "All Banks") then
							if(location.locationType == BAG_BANK or location.locationType == BAG_GUILDBANK)then
								itemCount = itemCount + location.itemCount
							end
						elseif(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "All Guild Banks") then
							if(location.locationType == BAG_GUILDBANK)then
								itemCount = itemCount + location.itemCount
							end
						elseif(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "All Characters") then
							if(location.locationType == BAG_BACKPACK or location.locationType == BAG_WORN)then
								itemCount = itemCount + location.itemCount
							end
						elseif(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "Bank and Characters") then
							if(location.locationType == BAG_BANK or location.locationType == BAG_BACKPACK)then
								itemCount = itemCount + location.itemCount
							end
						elseif(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST == "Bank Only") then
							if(location.locationType == BAG_BANK)then
								itemCount = itemCount + location.itemCount
							end
						else --Not a preset, must be a specific guildbank or character
							if(locationName == IN2_CURRENTLY_VISIBLE_INVENTORY_LIST)then
								itemCount = itemCount + location.itemCount
							end
						end
					end
				end
				tempDataLine = { link = iLink, amt = itemCount, icon = iconFile, name = itemName, quality = itemQuality }
				if(itemCount > 0)then
					if(IN2_INVENTORY_FRAME.FilterControl.activeSubFilter.filterType == 0) then
						if( searchFilter ~= nil) then
								--local _, name = IIfA.IN2_DissectItemLink(itemLink)
								if( zo_strformat("<<Z:1>>", itemName):find(zo_strformat("<<Z:1>>", searchFilter)) ~= nil ) then
									table.insert(DataLines, tempDataLine)
								end
						else
							table.insert(DataLines, tempDataLine)
						end
					elseif(itemTypeFilter == IN2_INVENTORY_FRAME.FilterControl.activeSubFilter.filterType) then
						if( searchFilter ~= nil) then
								--local _, name = IIfA.IN2_DissectItemLink(itemLink)
								if( zo_strformat("<<Z:1>>", itemName):find(zo_strformat("<<Z:1>>", searchFilter)) ~= nil ) then
									table.insert(DataLines, tempDataLine)
								end
						else
							table.insert(DataLines, tempDataLine)
						end
					end
				end
			end
		end
	end
	--sort datalines
	function IN2_SortCompareUp(a, b)
		--local _, _, name1 = a.link:match("|H(.-):(.-)|h(.-)|h")
		--local _, _, name2 = b.link:match("|H(.-):(.-)|h(.-)|h")
		local name1 = a.name
		local name2 = b.name
		return (name1 or "") < (name2 or "")
	end
	function IN2_SortCompareDown(a, b)
		return IN2_SortCompareUp(b, a)
	end

	local sortDirection = IN2_INVENTORY_FRAME_SCROLL.SortBar.SortName.direction
	if(sortDirection == IN2_SORT_UP) then
		table.sort(in2scroll.DataLines, IN2_SortCompareUp)
	elseif(sortDirection == IN2_SORT_DOWN) then
		table.sort(in2scroll.DataLines, IN2_SortCompareDown)
	end
end

function IIfA.IN2_UpdateIN2InventoryScroll(...)
	local in2scroll = IN2_INVENTORY_FRAME_SCROLL
	local index = 0
	local curLine = nil
	------------------------------------------------------
	in2scroll.DataOffset = in2scroll.DataOffset or 0
	if in2scroll.DataOffset < 0 then in2scroll.DataOffset = 0 end
	if #in2scroll.DataLines == 0 then
		for i = 1,in2scroll.MaxLines do
			curLine = in2scroll.Lines[i]
			if( i == 1) then
				curLine.Link = ""
				curLine.Icon:SetTexture("")
				curLine.Icon:SetAlpha(0)
				curLine.Text:SetText("no matches found")
				curLine.Amt:SetText("")
				curLine.Text:SetColor(255, 255, 255, 1)
				curLine.bg:SetAlpha(0)
			else
				curLine.Link = ""
				curLine.Icon:SetTexture("")
				curLine.Icon:SetAlpha(0)
				curLine.Text:SetText("")
				curLine.Amt:SetText("")
				curLine.bg:SetAlpha(0)
			end
		end
		return
	end
	in2scroll.Slider:SetMinMax(0,#in2scroll.DataLines - in2scroll.MaxLines)
	local curLine, curData, quality, name, color, curDataText, curLineMouseEnterHandler
	local r, g, b, a
	for i = 1,in2scroll.MaxLines do
		curLine = in2scroll.Lines[i]
		curData = in2scroll.DataLines[in2scroll.DataOffset + i]
		if( curData ~= nil) then
			--local _, _, _, quality, color = IIfA.IN2_DissectItemLink(curData.link) --deprecated in DBV2
			quality = curData.quality
			name = "[" .. curData.name .. "]"
			r, g, b, a = 1, 1, 1, 1
			if (quality) then
				color = GetItemQualityColor(quality)
				r, g, b, a = color:UnpackRGBA()
			end
			curDataText = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
			curLine.Link = curData.link
			curLine.Icon:SetTexture(curData.icon)
			curLine.Icon:SetAlpha(1)
			curLine.Text:SetText(curDataText)
			curLine.Text:SetColor(r, g, b, a)
			curLine.Amt:SetText(curData.amt)
			curLine.bg:SetAlpha(1)
			if(moc() == curLine) then
				curLineMouseEnterHandler = in2scroll.Lines[i]:GetHandler("OnMouseEnter")
				curLineMouseEnterHandler(curLine)
			end
		else
			curLine.Link = ""
			curLine.Icon:SetTexture("")
			curLine.Icon:SetAlpha(0)
			curLine.Text:SetText("")
			curLine.Amt:SetText("")
			curLine.bg:SetAlpha(0)
		end
	end
end

function IIfA.IN2_CreateIN2InventoryScroll(controlName, owner, parent)

	local in2scroll = owner.insideScroll:GetNamedChild("ScrollChild")

	in2scroll.DataOffset = 0
	in2scroll.MaxLines = 14
	in2scroll.DataLines = {}
	in2scroll.Lines = {}

	in2scroll:SetHeight((in2scroll.MaxLines * 40) + 10)
	in2scroll:SetWidth(360)
	in2scroll:SetMouseEnabled(true)
	in2scroll:SetHandler("OnMouseWheel",function(self,delta)
		local value = in2scroll.DataOffset - delta
		if value < 0 then
			value = 0
		elseif value > #in2scroll.DataLines - in2scroll.MaxLines then
			value = #in2scroll.DataLines - in2scroll.MaxLines
		end
		in2scroll.DataOffset = value
		in2scroll.Slider:SetValue(in2scroll.DataOffset)
		IIfA.IN2_UpdateIN2InventoryScroll()
	end)
	in2scroll:SetHandler("OnShow",function(self)
		IIfA.IN2_UpdateScrollDataLinesData()
		IIfA.IN2_UpdateIN2InventoryScroll()
	end)

	local tex = "/esoui/art/miscellaneous/scrollbox_elevator.dds"
	in2scroll.Slider = WINDOW_MANAGER:CreateControl(nil,in2scroll,CT_SLIDER)
	in2scroll.Slider:SetDimensions(16,in2scroll:GetHeight())
	in2scroll.Slider:SetMouseEnabled(true)
	in2scroll.Slider:SetThumbTexture(tex,tex,tex,16,50,0,0,1,1)
	in2scroll.Slider:SetValue(0)
	in2scroll.Slider:SetValueStep(1)
	in2scroll.Slider:SetAnchor(LEFT,in2scroll,LEFT, in2scroll:GetWidth(),25)

	in2scroll.Slider:SetHandler("OnValueChanged",function(self,value,eventReason)
		in2scroll.DataOffset = zo_min(value,#in2scroll.DataLines - in2scroll.MaxLines)
		IIfA.IN2_UpdateIN2InventoryScroll()
	end)

	in2scroll.SortBar = WINDOW_MANAGER:CreateControl(in2scroll:GetName().."SortBar",in2scroll,CT_CONTROL)
	in2scroll.SortBar:SetDimensions(in2scroll:GetWidth(),40)
-- 2015-3-30 AssemblerManiac - moved the sort bar down 60 to leave room for filter icons
	in2scroll.SortBar:SetAnchor(TOPLEFT,in2scroll,TOPLEFT,0,85)
	--in2scroll.SortBar:SetAnchor(BOTTOMRIGHT,in2scroll,TOPRIGHT,0,0)

	in2scroll.SortBar.SortName = WINDOW_MANAGER:CreateControl(nil,in2scroll.SortBar,CT_LABEL)
	in2scroll.SortBar.SortName:SetAnchor(LEFT,in2scroll.SortBar,LEFT,45,0)
	in2scroll.SortBar.SortName:SetHidden(false)
	in2scroll.SortBar.SortName:SetFont("ZoFontGameLargeBoldShadow")
	in2scroll.SortBar.SortName:SetText("Name")
	in2scroll.SortBar.SortName:SetMouseEnabled(true)

	---/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds
	---/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds
	---/esoui/art/miscellaneous/list_sortheader_icon_sortover.dds
	in2scroll.SortBar.SortName.icon = WINDOW_MANAGER:CreateControl(nil,in2scroll.SortBar.SortName,CT_TEXTURE)
	in2scroll.SortBar.SortName.icon:SetDimensions(20,20)
	in2scroll.SortBar.SortName.icon:SetAnchor(LEFT, in2scroll.SortBar.SortName, RIGHT, 2, 0)
	in2scroll.SortBar.SortName.icon:SetTexture("") -- texture will toggle based on current sort
	in2scroll.SortBar.SortName.icon:SetTextureCoords(0,1,0,1)
	in2scroll.SortBar.SortName.icon:SetAlpha(0)

	-- 2015-3-30 - AssemblerManiac - take sort order from global setting
	in2scroll.SortBar.SortName.direction = IIfA.InventoryFrame_SortOrder
	-- was - IN2_SORT_OFF -- set default to OFF -- sorting causing client crashes.. continue to investigate...
	--[[]]

	-- 2015-3-30 - AssemblerManiac - make the sort indicator show as currently set
	if(in2scroll.SortBar.SortName.direction == IN2_SORT_UP)then
		in2scroll.SortBar.SortName.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds")
		in2scroll.SortBar.SortName.icon:SetAlpha(1)
	elseif(in2scroll.SortBar.SortName.direction == IN2_SORT_DOWN) then
		in2scroll.SortBar.SortName.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds")
		in2scroll.SortBar.SortName.icon:SetAlpha(1)
	else
		in2scroll.SortBar.SortName.icon:SetTexture("")
		in2scroll.SortBar.SortName.icon:SetAlpha(0)
	end

	in2scroll.SortBar.SortName:SetHandler("OnMouseEnter",function(self)
		--see if there is any way to change the text onmouseover
		if(self.direction == IN2_SORT_UP or self.direction == IN2_SORT_DOWN) then
			self.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_over.dds")
			self.icon:SetAlpha(1)
		else
			self.icon:SetTexture("")
			self.icon:SetAlpha(0)
		end
	end)
	in2scroll.SortBar.SortName:SetHandler("OnMouseExit",function(self)
		if(self.direction == IN2_SORT_UP)then
			 self.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds")
			self.icon:SetAlpha(1)
		elseif(self.direction == IN2_SORT_DOWN) then
			self.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds")
			self.icon:SetAlpha(1)
		else
			self.icon:SetTexture("")
			self.icon:SetAlpha(0)
		end
	end)
	in2scroll.SortBar.SortName:SetHandler("OnMouseUp",function(self)
		if(self.direction == IN2_SORT_OFF) then
			self.direction = IN2_SORT_UP
			IIfA.InventoryFrame_SortOrder = IN2_SORT_UP
		elseif(self.direction == IN2_SORT_UP)then
			self.direction = IN2_SORT_DOWN
			IIfA.InventoryFrame_SortOrder = IN2_SORT_DOWN
		elseif(self.direction == IN2_SORT_DOWN)then
			self.direction = IN2_SORT_OFF
			IIfA.InventoryFrame_SortOrder = IN2_SORT_OFF
		end
		if(self.direction == IN2_SORT_UP)then
			self.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds")
			self.icon:SetAlpha(1)
		elseif(self.direction == IN2_SORT_DOWN) then
			self.icon:SetTexture("/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds")
			self.icon:SetAlpha(1)
		else
			self.icon:SetTexture("")
			self.icon:SetAlpha(0)
		end
		local searchFilter = IN2_INVENTORY_FRAME.SearchControl.edit:GetText()
		IIfA.IN2_UpdateScrollDataLinesData(searchFilter)
		IIfA.IN2_UpdateIN2InventoryScroll()
	end)

	in2scroll.SortBar.Share = WINDOW_MANAGER:CreateControl(in2scroll.SortBar:GetName().."ShareButton",in2scroll,CT_TEXTURE)
	in2scroll.SortBar.Share:SetDimensions(20,20)
	in2scroll.SortBar.Share:SetAnchor(RIGHT,in2scroll.SortBar,RIGHT,-25,0)
	in2scroll.SortBar.Share:SetTexture("IIfA/assets/sharetochat.dds")
	in2scroll.SortBar.Share:SetTextureCoords(0,1,0,1)
	in2scroll.SortBar.Share:SetDrawLayer(0)
	in2scroll.SortBar.Share:SetDrawLevel(2)
	in2scroll.SortBar.Share:SetDrawTier(1)
	in2scroll.SortBar.Share:SetMouseEnabled(true)
	in2scroll.SortBar.Share:SetHandler("OnMouseEnter", function(control)
		InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, 0)
		InformationTooltip:SetHidden(false)
		InformationTooltip:ClearLines()
		InformationTooltip:AddLine("Doubleclick an item to add link to chat.")
	end)
	in2scroll.SortBar.Share:SetHandler("OnMouseExit", function(control)
		InformationTooltip:SetHidden(true)
		InformationTooltip:ClearLines()
	end)


	in2scroll.icon = WINDOW_MANAGER:CreateControl(nil,in2scroll,CT_TEXTURE)
	in2scroll.icon:SetDimensions(380,380)
	in2scroll.icon:SetAnchor(CENTER, in2scroll, CENTER, -15, 0)
-- 2015-3-30 AssemblerManiac - changed icon name below to match actual filename in the assets directory
	in2scroll.icon:SetTexture("IIfA/assets/inventoryinsight_icon.dds") -- texture will toggle based on current sort
	in2scroll.icon:SetTextureCoords(0,1,0,1)
	in2scroll.icon:SetAlpha(.10)

	for i=1,in2scroll.MaxLines do
		in2scroll.Lines[i] = WINDOW_MANAGER:CreateControl(in2scroll:GetName().."Line"..i,in2scroll,CT_CONTROL)
		in2scroll.Lines[i]:SetDimensions(in2scroll:GetWidth(),40)
		if i == 1 then
			in2scroll.Lines[i]:SetAnchor(TOPLEFT,in2scroll.SortBar,TOPLEFT,5,40)
			--in2scroll.Lines[i]:SetAnchor(TOPRIGHT,in2scroll,TOPRIGHT,0,5)
		else
			in2scroll.Lines[i]:SetAnchor(TOPLEFT,in2scroll.Lines[i-1],BOTTOMLEFT,0,0)
			--in2scroll.Lines[i]:SetAnchor(TOPRIGHT,in2scroll.Lines[i-1],BOTTOMRIGHT,0,0)
		end

		in2scroll.Lines[i].bg = WINDOW_MANAGER:CreateControl(in2scroll.Lines[i]:GetName().."BG", in2scroll.Lines[i], CT_TEXTURE)
		in2scroll.Lines[i].bg :SetTexture("/esoui/art/actionbar/classbar_bg.dds")
		in2scroll.Lines[i].bg :SetTextureCoords(0,1,0,1)
		in2scroll.Lines[i].bg :SetAlpha(.75)
		in2scroll.Lines[i].bg :SetAnchor(TOPLEFT, in2scroll.Lines[i], TOPLEFT, -25, 0)
		in2scroll.Lines[i].bg :SetAnchor(BOTTOMRIGHT, in2scroll.Lines[i], BOTTOMRIGHT, 25, 5)

		in2scroll.Lines[i].Icon = WINDOW_MANAGER:CreateControl(in2scroll.Lines[i]:GetName().."Icon",in2scroll.Lines[i],CT_TEXTURE)
		in2scroll.Lines[i].Icon:SetDimensions(30,30)
		in2scroll.Lines[i].Icon:SetAnchor(LEFT,in2scroll.Lines[i],LEFT,5,0)
		in2scroll.Lines[i].Icon:SetTexture("/esoui/art/icons/icon_missing.dds")
		in2scroll.Lines[i].Icon:SetTextureCoords(0,1,0,1)
		in2scroll.Lines[i].Icon:SetDrawLayer(0)
		in2scroll.Lines[i].Icon:SetDrawLevel(2)
		in2scroll.Lines[i].Icon:SetDrawTier(1)
		in2scroll.Lines[i].Icon:SetAlpha(0)

		in2scroll.Lines[i].Amt = WINDOW_MANAGER:CreateControl(in2scroll.Lines[i]:GetName().."Amt",in2scroll.Lines[i],CT_LABEL)
		in2scroll.Lines[i].Amt:SetFont(LMP:Fetch('font', IIfA.GetTooltipFont()).."|"..IIfA.GetTooltipFontSize())
		in2scroll.Lines[i].Amt:SetDimensions(60,30)
		in2scroll.Lines[i].Amt:SetAnchor(RIGHT,in2scroll.Lines[i],RIGHT,5,0)
		--in2scroll.Lines[i].Amt:SetText(i)

		in2scroll.Lines[i].Text = WINDOW_MANAGER:CreateControl(in2scroll.Lines[i]:GetName().."Text",in2scroll.Lines[i],CT_LABEL)
		in2scroll.Lines[i].Text:SetFont(LMP:Fetch('font', IIfA.GetTooltipFont()).."|"..IIfA.GetTooltipFontSize())
		in2scroll.Lines[i].Text:SetDimensions(in2scroll.Lines[i]:GetWidth()-90,30)
		in2scroll.Lines[i].Text:SetAnchor(LEFT,in2scroll.Lines[i].Icon,RIGHT,5,0)
		in2scroll.Lines[i].Text:SetAnchor(RIGHT,in2scroll.Lines[i].Amt,LEFT,5,0)
		if( i == 1) then
			in2scroll.Lines[i].Text:SetText("       No Collected Data")
		else
			in2scroll.Lines[i].Text:SetText("")
		end

		in2scroll.Lines[i]:SetHidden(false)
		in2scroll.Lines[i]:SetMouseEnabled(true)

		in2scroll.Lines[i]:SetHandler("OnMouseEnter", function(control)
			--if( control.Text:GetText() ~= "" and control.Link ~= "") then
			if( control.Link ~= "") then
				IN2_CURRENT_MOUSEOVER_LINK = control.Link
				InitializeTooltip(ItemTooltip, control, LEFT, 0, 0, 0)
--				ItemTooltip:SetHidden(false)
--				ItemTooltip:ClearLines()
				ItemTooltip:SetLink(control.Link)
			end
		end)
		in2scroll.Lines[i]:SetHandler("OnMouseExit", function(self)
--			ItemTooltip:SetHidden(true)
			ClearTooltip(ItemTooltip)
			--ItemTooltip.animation:PlayFromStart()
		end)

		in2scroll.Lines[i]:SetHandler("OnMouseDoubleClick", function(control)
			if(control.Link) then
				if(control.Link ~= "") then
					ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText()..zo_strformat(SI_TOOLTIP_ITEM_NAME, control.Link))
				end
			end
		end)
	end

	function in2scroll:UpdateFont()
		for i=1,in2scroll.MaxLines do
			in2scroll.Lines[i].Text:SetFont(LMP:Fetch('font', IIfA.GetTooltipFont()).."|"..IIfA.GetTooltipFontSize())
			in2scroll.Lines[i].Amt:SetFont(LMP:Fetch('font', IIfA.GetTooltipFont()).."|"..IIfA.GetTooltipFontSize())
		end
	end
	--[[TESTING
	ZO_Menu_Initialize()
	AddMenuItem("Link to chat", function() d(IN2_CURRENT_MOUSEOVER_LINK) end, nil, "ZoFontWinH4")
	]]
	IN2_INVENTORY_FRAME_SCROLL = in2scroll
end

function IIfA.IN2_CreateIN2FilterControl( parent )
	if(parent) then
		local FilterControl = WINDOW_MANAGER:CreateControl(parent:GetName().."Sort",parent,CT_CONTROL)
		FilterControl.FilterButtons = {}
-- 2015-3-30 AssemblerManiac - moved the Filter Icons into the window instead of hanging outside
-- 3-30 orig		SortControl:SetAnchor(TOPLEFT, parent, TOPRIGHT, 0, 0)
		FilterControl:SetAnchor(TOPLEFT, parent, TOPLEFT, 110, 60)
		FilterControl:SetDimensions(32, 150)
		local filterIndex = 0
		for i, equipType in pairs(IIfA.filterByEquipTypes) do
			FilterControl.FilterButtons[filterIndex] = WINDOW_MANAGER:CreateControl(FilterControl:GetName().."FilterButton"..filterIndex,FilterControl,CT_TEXTURE)
			FilterControl.FilterButtons[filterIndex]:SetDimensions(30,30)
			FilterControl.FilterButtons[filterIndex].over = WINDOW_MANAGER:CreateControl(FilterControl:GetName().."FilterButtonOver"..filterIndex,FilterControl,CT_TEXTURE)
			FilterControl.FilterButtons[filterIndex].over:SetDimensions(30,30)
			if filterIndex == 0 then
				FilterControl.FilterButtons[filterIndex].over:SetTexture(equipType.mouseOverEquipType)
				FilterControl.FilterButtons[filterIndex].over:SetAnchor(TOP,FilterControl,TOP,1,1)
				FilterControl.FilterButtons[filterIndex]:SetTexture(equipType.enabledEquipType)
				FilterControl.FilterButtons[filterIndex]:SetAnchor(TOP,FilterControl,TOP,1,1)
				FilterControl.FilterButtons[filterIndex].isSelected = true
				FilterControl.activeSubFilter = FilterControl.FilterButtons[filterIndex]
			else
				FilterControl.FilterButtons[filterIndex].over:SetTexture(equipType.mouseOverEquipType)
-- 2015-3-30 - AssemblerManiac - moved the filter buttons to below the selection list, looks more like normal inventory window
-- 3-30 orig	FilterControl.FilterButtons[filterIndex].over:SetAnchor(TOP, FilterControl.FilterButtons[filterIndex-1], TOP, 0, 1)
				FilterControl.FilterButtons[filterIndex].over:SetAnchor(TOPLEFT,FilterControl.FilterButtons[filterIndex-1],TOPRIGHT,1,0)
				FilterControl.FilterButtons[filterIndex]:SetTexture(equipType.disabledEquipType)
-- 3-30 orig	FilterControl.FilterButtons[filterIndex]:SetAnchor(TOP, FilterControl.FilterButtons[filterIndex-1], TOP, 0, 1)
				FilterControl.FilterButtons[filterIndex]:SetAnchor(TOPLEFT,FilterControl.FilterButtons[filterIndex-1],TOPRIGHT,1,0)
				FilterControl.FilterButtons[filterIndex].isSelected = false
			end
			FilterControl.FilterButtons[filterIndex].over:SetAlpha(0)
			FilterControl.FilterButtons[filterIndex]:SetTextureCoords(0,1,0,1)
			FilterControl.FilterButtons[filterIndex]:SetAlpha(1)
			FilterControl.FilterButtons[filterIndex]:SetMouseEnabled(true)
			FilterControl.FilterButtons[filterIndex].filterType = i
			FilterControl.FilterButtons[filterIndex]:SetHandler("OnMouseEnter", function(self)
				--self:SetTexture(IIfA.filterByEquipTypes[self.filterType].mouseOverEquipType)
				ZO_Tooltips_ShowTextTooltip(self, TOP, IIfA.filterByEquipTypesStrings[self.filterType])
--[[
				InitializeTooltip(InformationTooltip, self, TOP, 0, 0, 0)
				InformationTooltip:SetHidden(false)
				InformationTooltip:ClearLines()
				InformationTooltip:AddLine(IIfA.filterByEquipTypesStrings[self.filterType])
--]]
				self.over:SetAlpha(1)
			end)
			FilterControl.FilterButtons[filterIndex]:SetHandler("OnMouseExit", function(self)
				if(self.isSelected)then
					self:SetTexture(IIfA.filterByEquipTypes[self.filterType].enabledEquipType)
				else
					self:SetTexture(IIfA.filterByEquipTypes[self.filterType].disabledEquipType)
				end
	  			ZO_Tooltips_HideTextTooltip()
--				InformationTooltip:SetHidden(true)
--				InformationTooltip:ClearLines()
				self.over:SetAlpha(0)
			end)
			FilterControl.FilterButtons[filterIndex]:SetHandler("OnMouseUp", function(self)
				if(self.isSelected)then
					-- do nothing.. already selected
				else
					self:SetTexture(equipType.enabledEquipType)
					self.isSelected = true
					self:GetParent().activeSubFilter:SetTexture(IIfA.filterByEquipTypes[self:GetParent().activeSubFilter.filterType].disabledEquipType)
					self:GetParent().activeSubFilter.isSelected = false
					self:GetParent().activeSubFilter = self
					local searchFilter = IN2_INVENTORY_FRAME.SearchControl.edit:GetText()
					IIfA.IN2_UpdateScrollDataLinesData(searchFilter)
					IIfA.IN2_UpdateIN2InventoryScroll()
					PlaySound(SOUNDS.MENU_BAR_CLICK)
				end
			end)


			filterIndex = filterIndex + 1
		end
		return FilterControl
	end
end

function IIfA.IN2_CreateIN2FrameRemoveFromSceneButton( parent )
	if(parent) then
		local SceneToggle = WINDOW_MANAGER:CreateControl(parent:GetName().."FrameClose",parent,CT_CONTROL)
		SceneToggle:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -5, 5)
		SceneToggle:SetMouseEnabled(false)
		SceneToggle:SetInheritAlpha(false)
		SceneToggle:SetDimensions(40,20)

		SceneToggle.icon = WINDOW_MANAGER:CreateControl(nil,SceneToggle,CT_TEXTURE)
		SceneToggle.icon:SetDimensions(20,20)
		SceneToggle.icon:SetAnchor(RIGHT, SceneToggle, RIGHT, 0, 0)
		SceneToggle.icon:SetTexture("/esoui/art/buttons/decline_up.dds")
		SceneToggle.icon:SetTextureCoords(0,1,0,1)
		SceneToggle.icon:SetAlpha(1)
		SceneToggle.icon:SetMouseEnabled(true)

		SceneToggle.icon:SetHandler("OnMouseEnter",function(self)
			SceneToggle.over:SetAlpha(1)
			InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
			InformationTooltip:SetHidden(false)
			InformationTooltip:ClearLines()
			InformationTooltip:AddLine("Disable in scene:\n"..IN2_INVENTORY_FRAME.ActiveScene)
		end)
		SceneToggle.icon:SetHandler("OnMouseExit",function(self)
			SceneToggle.over:SetAlpha(0)
			InformationTooltip:SetHidden(true)
			InformationTooltip:ClearLines()
		end)
		SceneToggle.icon:SetHandler("OnMouseDown",function(self)
			SceneToggle.icon:SetTexture("/esoui/art/buttons/decline_down.dds")
		end)
		SceneToggle.icon:SetHandler("OnMouseUp",function(self)
			SceneToggle.icon:SetTexture("/esoui/art/buttons/decline_up.dds")
			InformationTooltip:SetHidden(true)
			InformationTooltip:ClearLines()
			IIfA.IN2_StatusAlert("[IIfA]:InventoryFrameHiddenInScene["..IN2_INVENTORY_FRAME.ActiveScene.."]")
			IIfA.settings.in2InventoryFrameScenes[IN2_INVENTORY_FRAME.ActiveScene] = false
			IN2_INVENTORY_FRAME:SetHidden(true)
			if(IN2_INVENTORY_FRAME.ActiveScene == "inventory") then
				ZO_SharedThinLeftPanelBackground:SetWidth(240)
				ZO_SharedThinLeftPanelBackground:SetHidden(false)
			else
				ZO_SharedThinLeftPanelBackground:SetHidden(true)
				ZO_SharedThinLeftPanelBackgroundLeft:SetHidden(false)
				ZO_SharedThinLeftPanelBackgroundRight:SetHidden(false)
			end
		end)

		local texture = CT_TEXTURE or "/esoui/art/buttons/decline_over.dds"
		SceneToggle.over = WINDOW_MANAGER:CreateControl(nil,SceneToggle,texture)
		SceneToggle.over:SetDimensions(20,20)
		SceneToggle.over:SetAnchor(RIGHT, SceneToggle, RIGHT, 0, 0)
		SceneToggle.over:SetTexture("/esoui/art/buttons/decline_over.dds")
		SceneToggle.over:SetTextureCoords(0,1,0,1)
		SceneToggle.over:SetAlpha(0)

		return SceneToggle
	end
end

function IIfA.IN2_CreateIN2FrameToggle( parent )
	if(parent) then
		local FrameToggle = WINDOW_MANAGER:CreateControl(parent:GetName().."FrameToggle",parent,CT_CONTROL)
		FrameToggle:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -30, 5)
		FrameToggle:SetMouseEnabled(false)
		FrameToggle:SetInheritAlpha(false)
		FrameToggle:SetDimensions(40,20)

		FrameToggle.icon = WINDOW_MANAGER:CreateControl(nil,FrameToggle,CT_TEXTURE)
		FrameToggle.icon:SetDimensions(20,20)
		FrameToggle.icon:SetAnchor(RIGHT, FrameToggle, RIGHT, 0, 0)
		FrameToggle.icon:SetTexture("/esoui/art/buttons/minimize_normal.dds")
		FrameToggle.icon:SetTextureCoords(0,1,0,1)
		FrameToggle.icon:SetAlpha(1)
		FrameToggle.icon:SetMouseEnabled(true)

		parent.minimized = false -- set default to in order

		FrameToggle.icon:SetHandler("OnMouseEnter",function(self)
			FrameToggle.over:SetAlpha(1)
			InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
			InformationTooltip:SetHidden(false)
			InformationTooltip:ClearLines()
			if(IN2_INVENTORY_FRAME.minimized) then
-- 2015-3-30 AssemblerManiac - changed text from Maxmize to Restore (matches windows nomenclature better since maximized would take up whole screen)
				InformationTooltip:AddLine("Restore")
			else
				InformationTooltip:AddLine("Minimize")
			end
		end)
		FrameToggle.icon:SetHandler("OnMouseExit",function(self)
			FrameToggle.over:SetAlpha(0)
			InformationTooltip:SetHidden(true)
			InformationTooltip:ClearLines()
		end)
		FrameToggle.icon:SetHandler("OnMouseDown",function(self)
			if(IN2_INVENTORY_FRAME.minimized) then
				self:SetTexture("/esoui/art/buttons/maximize_mousedown.dds")
			else
				self:SetTexture("/esoui/art/buttons/minimize_mousedown.dds")
			end
		end)
		FrameToggle.icon:SetHandler("OnMouseUp",function(self)
			if(IN2_INVENTORY_FRAME.minimized) then
				self:SetTexture("/esoui/art/buttons/maximize_normal.dds")
				IN2_INVENTORY_FRAME.minimized = not IN2_INVENTORY_FRAME.minimized
				IN2_INVENTORY_FRAME:ToggleMinimized()
			else
				self:SetTexture("/esoui/art/buttons/minimize_normal.dds")
				IN2_INVENTORY_FRAME.minimized = not IN2_INVENTORY_FRAME.minimized
				IN2_INVENTORY_FRAME:ToggleMinimized()
			end
			InformationTooltip:SetHidden(true)
			InformationTooltip:ClearLines()
		end)

		FrameToggle.over = WINDOW_MANAGER:CreateControl(nil,FrameToggle,CT_TEXTURE)
		FrameToggle.over:SetDimensions(20,20)
		FrameToggle.over:SetAnchor(RIGHT, FrameToggle, RIGHT, 0, 0)
		FrameToggle.over:SetTexture("/esoui/art/buttons/minmax_mouseover.dds")
		FrameToggle.over:SetTextureCoords(0,1,0,1)
		FrameToggle.over:SetAlpha(0)

		return FrameToggle
	end
end

function IIfA.IN2_CreateIN2FrameLock( parent )
	if(parent) then
		local FrameLock = WINDOW_MANAGER:CreateControl(parent:GetName().."FrameLock",parent,CT_CONTROL)
		FrameLock:SetAnchor(TOPLEFT, parent, TOPLEFT, -10, 5)
		FrameLock:SetMouseEnabled(false)
		FrameLock:SetInheritAlpha(false)
		FrameLock:SetDimensions(40,20)

		FrameLock.icon = WINDOW_MANAGER:CreateControl(nil,FrameLock,CT_TEXTURE)
		FrameLock.icon:SetDimensions(20,20)
		FrameLock.icon:SetAnchor(RIGHT, FrameLock, RIGHT, 0, 0)
		if(parent.locked) then
			FrameLock.icon:SetTexture("/esoui/art/miscellaneous/locked_up.dds")
		else
			FrameLock.icon:SetTexture("/esoui/art/miscellaneous/unlocked_up.dds")
		end
		FrameLock.icon:SetTextureCoords(0,1,0,1)
		FrameLock.icon:SetAlpha(1)
		FrameLock.icon:SetMouseEnabled(true)

		FrameLock.icon:SetHandler("OnMouseEnter",function(self)
			FrameLock.over:SetAlpha(1)
		end)
		FrameLock.icon:SetHandler("OnMouseExit",function(self)
			FrameLock.over:SetAlpha(0)
		end)
		FrameLock.icon:SetHandler("OnMouseDown",function(self)
			if(IN2_INVENTORY_FRAME.locked) then
				self:SetTexture("/esoui/art/miscellaneous/locked_down.dds")
			else
				self:SetTexture("/esoui/art/miscellaneous/unlocked_down.dds")
			end
		end)
		FrameLock.icon:SetHandler("OnMouseUp",function(self)
			if(IN2_INVENTORY_FRAME.locked) then
				IN2_INVENTORY_FRAME.locked = not IN2_INVENTORY_FRAME.locked
				IN2_INVENTORY_FRAME:SetMovable(true)
				PlaySound(SOUNDS.LOCKPICKING_UNLOCKED)
			else
				IN2_INVENTORY_FRAME.locked = not IN2_INVENTORY_FRAME.locked
				IN2_INVENTORY_FRAME:SetMovable(false)
				PlaySound(SOUNDS.LOCKPICKING_CHAMBER_LOCKED)
			end
			FrameLock:UpdateLock()
		end)

		FrameLock.over = WINDOW_MANAGER:CreateControl(nil,FrameLock,CT_TEXTURE)
		FrameLock.over:SetDimensions(20,20)
		FrameLock.over:SetAnchor(RIGHT, FrameLock, RIGHT, 0, 0)
		if(parent.locked) then
			FrameLock.over:SetTexture("/esoui/art/miscellaneous/locked_over.dds")
		else
			FrameLock.over:SetTexture("/esoui/art/miscellaneous/unlocked_over.dds")
		end
		FrameLock.over:SetTextureCoords(0,1,0,1)
		FrameLock.over:SetAlpha(0)

		function FrameLock:UpdateLock()
			if(IN2_INVENTORY_FRAME.locked) then
				self.icon:SetTexture("/esoui/art/miscellaneous/locked_up.dds")
				self.over:SetTexture("/esoui/art/miscellaneous/locked_over.dds")
			else
				self.icon:SetTexture("/esoui/art/miscellaneous/unlocked_up.dds")
				self.over:SetTexture("/esoui/art/miscellaneous/unlocked_over.dds")
			end
		end

		return FrameLock
	end
end

function IIfA.IN2_CreateIN2InventoryFrame(controlName, owner, parent)

	local frame = WINDOW_MANAGER:CreateControlFromVirtual(controlName, owner, "ZO_DefaultBackdrop")
	frame:ClearAnchors()
	frame:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -25, 40) --ZO_SharedThinLeftPanelBackground anchor
-- 2015-3-30 AssemblerManiac - changed height from 668 to 748 in all places that used 668 height
	frame:SetDimensions(405, 748)
	frame.controlType = CT_CONTROL
	frame.system = SETTING_TYPE_UI
	frame:SetHidden(false)
	frame:SetMouseEnabled(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetResizeHandleSize(5)
	frame:SetDimensionConstraints(405,30,405,748)

	frame.minimized = false
	frame.docked = false
	frame.locked = false

	frame.insideScroll = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."ScrollContainer", frame, "ZO_ScrollContainer")
	local insideScroll = frame.insideScroll
	insideScroll:SetAnchor(TOPLEFT, frame, TOPLEFT, 10, 20)
	insideScroll:SetAnchor(BOTTOMRIGHT, frame, BOTTOMRIGHT, -5, -5)
	local scrollframe = insideScroll:GetNamedChild("ScrollChild")

	frame.label = WINDOW_MANAGER:CreateControl(controlName.."Label", frame, CT_LABEL)
	local label = frame.label
	label:SetAnchor(TOP, frame, TOP, 0, 2)
	label:SetMouseEnabled(false)
	label:SetFont("ZoFontWinH4")
	label:SetText("-INVENTORY INSIGHT FROM ASHES-")
	label:SetColor(.772,.760,.619,1)

	frame:SetHandler("OnResizeStop", function(self)
			if(self:GetHeight() == 30 and self.minimized == false)then
				self.minimized = true
				self.insideScroll:SetHidden(true)
				self.FilterControl:SetHidden(true)
				self.SearchControl:SetHidden(true)
--				self.exportCSVDataBtn:SetHidden(true)
				PlaySound(SOUNDS.BACKPACK_WINDOW_CLOSE)
			elseif(self:GetHeight() > 30 and self.minimized == true)then
				self.minimized = false
				self.insideScroll:SetHidden(false)
				self.FilterControl:SetHidden(false)
				self.SearchControl:SetHidden(false)
--				self.exportCSVDataBtn:SetHidden(false)
				PlaySound(SOUNDS.BACKPACK_WINDOW_OPEN)
				self.minimized = false
			end
		end)

	frame.FilterControl = IIfA.IN2_CreateIN2FilterControl(frame)
	frame.FrameToggle = IIfA.IN2_CreateIN2FrameToggle(frame)
	frame.FrameClose = IIfA.IN2_CreateIN2FrameRemoveFromSceneButton(frame)
	frame.FrameLock = IIfA.IN2_CreateIN2FrameLock(frame)

--[[
	frame.exportCSVDataBtn = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."ExportCSVDataButton", frame, "ZO_DefaultButton")
	local exportCSVDataBtn = frame.exportCSVDataBtn
	exportCSVDataBtn:SetAnchor(BOTTOM, exportCSVDataLbl, BOTTOM, 0, -7)
	exportCSVDataBtn:SetWidth(250)
	exportCSVDataBtn:SetHeight(20)
	exportCSVDataBtn:SetText("Export to CSV")
	exportCSVDataBtn:SetHandler("OnClicked", IIfA.IN2_CreateOrShowExportFrame)

	--unfortunately need to remove this feature for now since they nerfed the FUCK out of strings. GG ZOE, GFG
	--disabling button and unconventionally hiding it...
	exportCSVDataBtn:SetEnabled(false)
	exportCSVDataBtn:SetAlpha(0)
	-----------------------------------------------------
--]]

	function frame:SaveFrameSceneLocation()
		local scene = self.ActiveScene
		local curLocked = self.locked
		local curMinimized = self.minimized
		local curX = self:GetLeft()
		local curY = self:GetTop()
		IIfA.IN2_DebugOutput(scene)
		if(scene and not self.docked)then
			IIfA.UpdateFrameSceneSettings(scene, curLocked, curMinimized, curX, curY)
		end
	end

	function frame:LoadFrameSceneLocation()
		local scene = self.ActiveScene
		IIfA.IN2_DebugOutput(scene)
		if(scene and not self.docked)then
			local newLocked, newMinimize, newX, newY =  IIfA.ReadFrameSceneSettings(scene)
			self.minimized = newMinimize
			self:ClearAnchors()
			self:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, newX, newY)
			self:ToggleMinimized()
			self:SetMovable(not newLocked)
			self.locked = newLocked
			self.FrameLock:UpdateLock()
		else
			self:ClearAnchors()
			self:SetAnchor(TOPRIGHT, ZO_SharedThinLeftPanelBackground, TOPRIGHT, -25, 20)
		end
	end

	function frame:ToggleMinimized()
		if(not self.minimized) then
			self:SetResizeHandleSize(5)
			self:SetDimensionConstraints(405, 30, 405, 748)
			self:SetHeight(7488)
			PlaySound(SOUNDS.BACKPACK_WINDOW_OPEN)
		else
			self:SetResizeHandleSize(0)
-- 2015-3-30 AssemblerManiac - bumped up height of minimized bar just a bit so dropdown icon doesn't get cut off
			self:SetDimensionConstraints(405, 30, 405, 33)
			self:SetHeight(33)
			PlaySound(SOUNDS.BACKPACK_WINDOW_CLOSE)
		end
		self.insideScroll:SetHidden(self.minimized)
		self.FilterControl:SetHidden(self.minimized)
		self.SearchControl:SetHidden(self.minimized)
--		self.exportCSVDataBtn:SetHidden(self.minimized)
	end

	return frame
end


function IIfA.IN2_CreateIN2InventoryDropdown(controlName, text, tooltip, validChoices, getFunc, setFunc, owner, parent)
	local dropdown = WINDOW_MANAGER:CreateControlFromVirtual(controlName, owner, "ZO_ComboBox")
	local entry = IIfA.GetDefaultFilter()
	dropdown:SetAnchor(TOP, parent, TOP, -8, 10)
	dropdown:SetDimensions(190, 25)
	dropdown.tooltipText = tooltip
	dropdown.valid = validChoices

	dropdown:SetHandler("OnShow", function()
		local selectedItem = IIfA.GetDefaultFilter()
		dropmenu:SetSelectedItem(selectedItem)
		setFunc(selectedItem)
	end)

	dropdown:SetHandler("OnMouseEnter", function(self)
		InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
		InformationTooltip:SetHidden(false)
		InformationTooltip:ClearLines()
		InformationTooltip:AddLine(tooltip)
	end)

	dropdown:SetHandler("OnMouseExit", function(self)
		InformationTooltip:SetHidden(true)
		InformationTooltip:ClearLines()
	end)

	local function OnItemSelect(_, choiceText, choice)
		--d(choiceText, choice)
		setFunc(choiceText)
	  PlaySound(SOUNDS.POSITIVE_CLICK)
	end

	for i=1,#validChoices do
		entry = dropdown.m_comboBox:CreateItemEntry(validChoices[i], OnItemSelect)
		dropdown.m_comboBox:AddItem(entry)
	end
	dropdown.m_comboBox:SelectFirstItem()


	dropdown.Info = WINDOW_MANAGER:CreateControl(dropdown:GetName().."Info",dropdown,CT_TEXTURE)
	dropdown.Info:SetDimensions(20,20)
	dropdown.Info:SetAnchor(LEFT,dropdown,RIGHT,5,0)
	dropdown.Info:SetTexture("/esoui/art/buttons/info_up.dds")
	dropdown.Info:SetTextureCoords(0,1,0,1)
	dropdown.Info:SetDrawLayer(0)
	dropdown.Info:SetDrawLevel(2)
	dropdown.Info:SetDrawTier(1)
	dropdown.Info:SetMouseEnabled(true)
	dropdown.Info:SetHandler("OnMouseEnter", function(self)
		self:SetTexture("/esoui/art/buttons/info_over.dds")
		local lastCollected, numItems, maxItems, curSearch, visibleList, numSlots = ""
		lastCollected, numItems, maxItems = IIfA.IN2_GetGuildBankDataInfo(IN2_CURRENTLY_VISIBLE_INVENTORY_LIST)
		if(lastCollected == "") then lastCollected = "|cFF0000-never-|r" end
		curSearch = IN2_INVENTORY_SEARCHBOX_CONTROL.edit:GetText()
		if(curSearch == "" or nil == curSearch) then curSearch = "-none-" end

		local curFilter = IIfA.filterByEquipTypesStrings[IN2_INVENTORY_FRAME.FilterControl.activeSubFilter.filterType] or ""

		if(lastCollected) then
			visibleList = IN2_CURRENTLY_VISIBLE_INVENTORY_LIST or visibleList
			numSlots = #IN2_INVENTORY_FRAME_SCROLL.DataLines or numSlots
			if(lastCollected ~= "|cFF0000-never-|r" )then
				local today = GetDate()
				local lastDate = lastCollected:match('(........)')
				if(today - lastDate > 0)then
					lastCollected = "|cFFA500"..lastCollected.."|r"
				end
				if(today - lastDate > 5)then
					lastCollected = "|cFF0000"..lastCollected.."|r"
				end
			end
			InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
			InformationTooltip:AddLine("Guild: "..visibleList.."\nLast collected: "..lastCollected.."\nSlots: "..numItems.."/"..maxItems.."\nCurrent Search: "..curSearch.."\nCurrent Filter: "..curFilter)
		else -- if not collected
			InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
			IIfA.AddToTooltip(InformationTooltip, visibleList, numSlots, curSearch, curFilter)
		end
	end)

	dropdown.Info:SetHandler("OnMouseExit", function(self)
		self:SetTexture("/esoui/art/buttons/info_up.dds")
		ClearTooltip(InformationTooltip)
	end)

	dropdown:SetHidden(false)
	dropdown:SetMouseEnabled(true)

	return dropdown
end

function IIfA.IN2_GetGuildBankDataInfo( guildName )
	local guildData = IIfA.data.guildBanks[guildName]
	if(guildData)then
		return guildData.lastCollected, guildData.items, guildData.maxSlots
	else
		return nil
	end
end

function IIfA.IN2_CreateIN2InventorySearchBox(controlName, owner, parent)
	local in2search = WINDOW_MANAGER:CreateControl(controlName,owner,CT_in2search)
	owner.SearchControl = in2search
	in2search:SetDimensions(parent:GetWidth()-5, 24)
	in2search:SetMouseEnabled(true)
	in2search:SetAnchor(TOPLEFT,parent,BOTTOMLEFT, 7, -36)
	--in2search:SetAnchor(TOPRIGHT,parent,BOTTOMRIGHT,0, 0)
	in2search:SetHidden(false)
	--in2search:SetInheritAlpha(false)

	in2search.label = WINDOW_MANAGER:CreateControl(controlName.."Label", in2search, CT_LABEL)
	local label = in2search.label
	label:SetDimensions(70, 24)
	label:SetAnchor(LEFT)
	label:SetFont("ZoFontWinH4")
	label:SetText("Search:")

	in2search.bg = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."BG", label, "ZO_EditBackdrop")
	local bg = in2search.bg
	bg:SetDimensions(parent:GetWidth()-85,24)
	--bg:SetAnchor(LEFT, label, RIGHT, 2, 0)
	bg:SetAnchor(TOPRIGHT, parent, BOTTOMRIGHT, -10, -36)
	in2search.edit = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."Edit", bg, "ZO_DefaultEditForBackdrop")
	--in2search.edit:SetText()
	--in2search.edit:SetHandler("OnFocusLost", function(self) setFunc(self:SetText()) end)

	in2search.tooltipText = "Search item name..."
	in2search.edit.tooltipText = "Search item name..."

	ZO_PreHookHandler(in2search.edit, "OnTextChanged", function(self)
		local text = in2search.edit:GetText()
		IIfA.IN2_UpdateScrollDataLinesData(text)
		IIfA.IN2_UpdateIN2InventoryScroll()
	end)
--	in2search:SetHandler("OnMouseEnter", ZO_Options_OnMouseEnter)
--	in2search:SetHandler("OnMouseExit", ZO_Options_OnMouseExit)
	in2search:SetHandler("OnMouseEnter", function(self)
			ZO_Tooltips_ShowTextTooltip(self, TOP, self.tooltipText)
			if(flash) then
				flash:SetHidden(false)
			end
		end)
	in2search:SetHandler("OnMouseExit", function(self)
			ZO_Tooltips_HideTextTooltip()
			if(flash) then
				flash:SetHidden(true)
			end
		end)

	in2search.edit:SetHandler("OnMouseEnter", function(self)
			ZO_Tooltips_ShowTextTooltip(self.parent, TOP, self.tooltipText)
			if(flash) then
				flash:SetHidden(false)
			end
		end)
	in2search.edit:SetHandler("OnMouseExit", function(self)
			ZO_Tooltips_HideTextTooltip()
			if(flash) then
				flash:SetHidden(true)
			end
		end)
	in2search.ClearButton = WINDOW_MANAGER:CreateControl(in2search:GetName().."ClearButton",in2search,CT_TEXTURE)
	in2search.ClearButton:SetDimensions(20,20)
	in2search.ClearButton:SetDrawLevel(15)
	in2search.ClearButton:SetDrawLayer(2)
	in2search.ClearButton:SetAnchor(RIGHT,in2search.edit,RIGHT,-5,0)
	in2search.ClearButton:SetTexture("/esoui/art/buttons/cancel_up.dds")
	in2search.ClearButton:SetTextureCoords(0,1,0,1)
	in2search.ClearButton:SetMouseEnabled(true)
	in2search.ClearButton:SetHandler("OnMouseEnter", function(self)
		self:SetTexture("/esoui/art/buttons/cancel_over.dds")
  		ZO_Tooltips_ShowTextTooltip(self, TOP, "Clear")
--[[		InitializeTooltip(InformationTooltip, self, LEFT, 0, 0, 0)
		InformationTooltip:SetHidden(false)
		InformationTooltip:ClearLines()
		InformationTooltip:AddLine("Reset")
--]]
	end)
	in2search.ClearButton:SetHandler("OnMouseExit", function(self)
		self:SetTexture("/esoui/art/buttons/cancel_up.dds")
		ZO_Tooltips_HideTextTooltip()
--		InformationTooltip:SetHidden(true)
--		InformationTooltip:ClearLines()
	end)
	in2search.ClearButton:SetHandler("OnMouseDown", function(self)
		self:SetTexture("/esoui/art/buttons/cancel_down.dds")
	end)
	in2search.ClearButton:SetHandler("OnMouseUp", function(self)
		self:SetTexture("/esoui/art/buttons/cancel_up.dds")
		self:GetParent().edit:SetText("")
		PlaySound(SOUNDS.DIALOG_DECLINE)
	end)

end

function IIfA.IN2_InitDefaultUIForInventoryFrameDocking( enable, frameWidth )
	if( enable ) then
		ZO_SharedThinLeftPanelBackground:SetWidth(ZO_SharedThinLeftPanelBackground:GetWidth() + frameWidth - 15)
	else
		ZO_SharedThinLeftPanelBackground:SetWidth(240)
	end
end

function IIfA.IN2_SetupIN2InventoryBackpack( setup, released )
-- IIfA.settings.in2ShowInventoryFrame, IIfA.settings.in2ReleaseInventoryFrame

	if( setup ) then -- if the inventory frame is supposed to be displayed
		IN2_CURRENTLY_VISIBLE_INVENTORY_LIST = IIfA.data.in2DefaultInventoryFrameView

		-- first run
		if(IN2_INVENTORY_FRAME == nil) then -- the frame is not initialized, first startup

			-- initialize InventoryFrame
			IN2_INVENTORY_FRAME = IIfA.IN2_CreateIN2InventoryFrame("IN2_INVENTORY_FRAME", ZO_SharedThinLeftPanelBackground, ZO_SharedThinLeftPanelBackground)
			IIfA.IN2_INVENTORY_FRAME = IN2_INVENTORY_FRAME
			IN2_INVENTORY_FRAME = IN2_INVENTORY_FRAME

			if( released ) then -- is not locked, can be moved around
				IIfA.IN2_InitDefaultUIForInventoryFrameDocking(false)
				IN2_INVENTORY_FRAME:ClearAnchors()
				IN2_INVENTORY_FRAME:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
			else
				IIfA.IN2_InitDefaultUIForInventoryFrameDocking(true, IN2_INVENTORY_FRAME:GetWidth())
				IN2_INVENTORY_FRAME:ClearAnchors()
				IN2_INVENTORY_FRAME:SetAnchor(CENTER, ZO_SharedThinLeftPanelBackground, CENTER, -25, 20)
			end

			IN2_INVENTORY_FRAME:SetMovable(released)
			IN2_INVENTORY_FRAME:SetMouseEnabled(true)
			IN2_INVENTORY_FRAME:SetHidden(false)
			IN2_INVENTORY_FRAME.docked = not released
			IN2_INVENTORY_FRAME:SetResizeHandleSize(5)
			IN2_INVENTORY_FRAME:SetDimensionConstraints(405,30,405,748)
			IN2_INVENTORY_FRAME.FrameToggle:SetHidden(not released)
			IN2_INVENTORY_FRAME.FrameLock:SetHidden(not released)


		-- second run
		else -- the inventory is not nil, this is at least the 2nd load up

			local IN2_INVENTORY_FRAME = IN2_INVENTORY_FRAME

			if( released ) then
				IIfA.IN2_InitDefaultUIForInventoryFrameDocking(false)
				IN2_INVENTORY_FRAME:ClearAnchors()
				IN2_INVENTORY_FRAME:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
			else
				IIfA.IN2_InitDefaultUIForInventoryFrameDocking(true, IN2_INVENTORY_FRAME:GetWidth())
				IN2_INVENTORY_FRAME:ClearAnchors()
				IN2_INVENTORY_FRAME:SetAnchor(CENTER, ZO_SharedThinLeftPanelBackground, TOPRIGHT, -25, 20)
			end

			IN2_INVENTORY_FRAME:SetMovable(not released)
			IN2_INVENTORY_FRAME:SetMouseEnabled(true)
			IN2_INVENTORY_FRAME:SetHidden(false)
			IN2_INVENTORY_FRAME.docked = not released
			IN2_INVENTORY_FRAME:SetResizeHandleSize(5)
			IN2_INVENTORY_FRAME:SetDimensionConstraints(405,30,405,748)
			IN2_INVENTORY_FRAME.FrameToggle:SetHidden(not released)
			IN2_INVENTORY_FRAME.FrameLock:SetHidden(not released)

		end -- inventory frame is initialized now


		-- todo: somewhere here should be the mistake... die! die!
		if(IN2_INVENTORY_FRAME_SCROLL == nil) then
			IIfA.IN2_CreateIN2InventoryScroll("IN2_INVENTORY_FRAME_SCROLL", IN2_INVENTORY_FRAME, IN2_INVENTORY_DROPDOWN_CONTROL)
		 end

		if(IN2_INVENTORY_SEARCHBOX_CONTROL == nil) then
			IIfA.IN2_CreateIN2InventorySearchBox("IN2_INVENTORY_SEARCHBOX_CONTROL", IN2_INVENTORY_FRAME, IN2_INVENTORY_FRAME)
		end


		if(IN2_INVENTORY_DROPDOWN_CONTROL == nil) then -- initialize dropdown control

			local inventoryList = IIfA.IN2_GetAccountInventoryList()
			IN2_INVENTORY_DROPDOWN_CONTROL = IIfA.IN2_CreateIN2InventoryDropdown(
				"IN2_INVENTORY_DROPDOWN_CONTROL",
				"Test",
				"Select inventory to view.",
				inventoryList,
				IIfA.IN2_GetVisibleInventory,
				IIfA.IN2_SetVisibleInventory,
				IN2_INVENTORY_FRAME_SCROLL,
				IN2_INVENTORY_FRAME_SCROLL
			)

		end

		IN2_INVENTORY_FRAME_SCROLL:SetHidden(false)
		IN2_INVENTORY_SEARCHBOX_CONTROL:SetHidden(false)
		IN2_INVENTORY_DROPDOWN_CONTROL:SetHidden(false)
		IIfA.IN2_UpdateScrollDataLinesData()
		IIfA.IN2_UpdateIN2InventoryScroll()

	else -- if the inventory frame is NOT supposed to be displayed

		if(IN2_INVENTORY_FRAME ~= nil) then
			IN2_INVENTORY_FRAME:SetHidden(true)
			IIfA.IN2_InitDefaultUIForInventoryFrameDocking(false)
		end
--[[
		if(IN2_INVENTORY_DROPDOWN_CONTROL ~= nil) then
			IN2_INVENTORY_DROPDOWN_CONTROL:SetHidden(true)
		end
		if(IN2_INVENTORY_FRAME_SCROLL ~= nil) then
			IN2_INVENTORY_FRAME_SCROLL:SetHidden(true)
		end
		if(IN2_INVENTORY_SEARCHBOX_CONTROL ~= nil) then
			IN2_INVENTORY_SEARCHBOX_CONTROL:SetHidden(true)
		end
--]]
	end

end

function IIfA.IN2_GetAccountInventoryList()
	local accountInventories = { "All", "All Banks", "All Guild Banks", "All Characters", "Bank and Characters", "Bank Only"  }
	if(IIfA.data.guildBanks) then
		for guildName, guild in pairs(IIfA.data.guildBanks) do
			table.insert(accountInventories, guildName)
		end
	end
	if(IIfA.data.accountCharacters) then
		for characterName, character in pairs(IIfA.data.accountCharacters) do
			--removing this check so the current character can also be viewed in the inventory frame
			--if(characterName ~= IIfA.currentCharacter) then
				table.insert(accountInventories, characterName)
			--end
		end
	end
	return accountInventories
end

function IIfA.IN2_CharacterInventories()
	local accountInventories = {}
	if(IIfA.data.accountCharacters) then
		for characterName, character in pairs(IIfA.data.accountCharacters) do
			table.insert(accountInventories, characterName)
		end
	end
	return accountInventories
end

function IIfA.IN2_GuildBanks()
	local accountInventories = {}
	if(IIfA.data.guildBanks) then
		for guildName, guild in pairs(IIfA.data.guildBanks) do
			table.insert(accountInventories, guildName)
		end
	end
	return accountInventories
end

function IIfA.IN2_SetVisibleInventory( newInventoryList )
	IN2_CURRENTLY_VISIBLE_INVENTORY_LIST = newInventoryList
	local searchFilter = IN2_INVENTORY_FRAME.SearchControl.edit:GetText()
	IIfA.IN2_UpdateScrollDataLinesData(searchFilter)
	IIfA.IN2_UpdateIN2InventoryScroll()
end

function IIfA.IN2_GetVisibleInventory()
	return IN2_CURRENTLY_VISIBLE_INVENTORY_LIST
end
