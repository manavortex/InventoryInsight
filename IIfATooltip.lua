local IIfA = IIfA

IIfA.racialTextures = {
    [ITEMSTYLE_NONE]    =   { styleName = "", styleTexture = ""},
    [ITEMSTYLE_RACIAL_ARGONIAN]    =   { styleName = "Argonian", styleTexture = "IIfA/assets/argonian.dds"},
    [ITEMSTYLE_RACIAL_BRETON]    =   { styleName = "Breton", styleTexture = "IIfA/assets/breton.dds"},
    [ITEMSTYLE_RACIAL_DARK_ELF]    =   { styleName = "Dark Elf", styleTexture = "IIfA/assets/dunmer.dds"},
    [ITEMSTYLE_RACIAL_HIGH_ELF]    =   { styleName = "High Elf", styleTexture = "IIfA/assets/altmer.dds"},
    [ITEMSTYLE_RACIAL_KHAJIIT]    =   { styleName = "Khajiit", styleTexture = "IIfA/assets/khajit.dds"},
    [ITEMSTYLE_RACIAL_NORD]    =   { styleName = "Nord", styleTexture = "IIfA/assets/nord.dds"},
    [ITEMSTYLE_RACIAL_ORC]    =   { styleName = "Orc", styleTexture = "IIfA/assets/orsimer.dds"},
    [ITEMSTYLE_RACIAL_REDGUARD]    =   { styleName = "RedGuard", styleTexture = "IIfA/assets/redguard.dds"},
    [ITEMSTYLE_RACIAL_WOOD_ELF]    =   { styleName = "Wood Elf", styleTexture = "IIfA/assets/bosmer.dds"},
    [ITEMSTYLE_UNIQUE] = { styleName = "Unique", styleTexture = "/esoui/art/campaign/campaign_tabicon_leaderboard_up.dds"},
    [11] = { styleName = "Aldmeri Dominion", styleTexture = "IIfA/assets/ancient.dds"},
    [12] = { styleName = "Ebonheart Pact", styleTexture = "IIfA/assets/ebonheart.dds"},
    [13] = { styleName = "Daggerfall Covenant", styleTexture = "IIfA/assets/daggerfall.dds"},
    [14] = { styleName = "Dwemer", styleTexture = "/esoui/art/campaign/campaign_tabicon_browser_up.dds"},
    [15] = { styleName = "Ancient Elf",styleTexture = "IIfA/assets/ancient.dds"},
    [16] = { styleName = "Imperial", styleTexture = "IIfA/assets/imperial.dds"},
    [17] = { styleName = "Reach", styleTexture = "IIfA/assets/Reach.dds"},
    [ITEMSTYLE_ENEMY_BANDIT] = { styleName = "Bandit", styleTexture = "IIfA/assets/Bandit.dds"},
    [ITEMSTYLE_ENEMY_PRIMITIVE] = { styleName = "Primitive", styleTexture = "IIfA/assets/Primitive.dds"},
    [ITEMSTYLE_ENEMY_DAEDRIC] = { styleName = "Daedric", styleTexture = "IIfA/assets/daedric.dds"},
    [21] = { styleName = "Warrior", styleTexture = "IIfA/assets/bosmer.dds"},
    [22] = { styleName = "Mage", styleTexture = "IIfA/assets/sorcerer.dds"},
    [23] = { styleName = "Rogue", styleTexture = "IIfA/assets/nightblade.dds"},
    [24] = { styleName = "Summoner", styleTexture = "IIfA/assets/sorcerer.dds"},
    [25] = { styleName = "Marauder", styleTexture = "IIfA/assets/dragonknight.dds"},
    [26] = { styleName = "Healer", styleTexture = "IIfA/assets/templar.dds"},
    [27] = { styleName = "Battlemage", styleTexture = "IIfA/assets/dragonknight.dds"},
    [28] = { styleName = "Nightblade", styleTexture = "IIfA/assets/nightblade.dds"},
    [29] = { styleName = "Ranger", styleTexture = "IIfA/assets/nightblade.dds"},
    [30] = { styleName = "Knight", styleTexture = "IIfA/assets/templar.dds"},
    [ITEMSTYLE_ENEMY_DRAUGR] = { styleName = "Draugr", styleTexture = "IIfA/assets/Draugr1.dds"},  --undead
    [ITEMSTYLE_ENEMY_MAORMER] = { styleName = "Maormer", styleTexture = "IIfA/assets/Maormer.dds"},  --snow elves
    [33] = { styleName = "Akaviri", styleTexture = "IIfA/assets/Akaviri.dds"},  --samurai
    [34] = { styleName = "Imperial", styleTexture = "IIfA/assets/imperial.dds"}
}

IIfA.itemEquipTypeTextures = {
    [EQUIP_TYPE_CHEST]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_COSTUME]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_FEET]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_HAND]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_HEAD]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_INVALID]  =   "",
    [EQUIP_TYPE_LEGS]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_MAIN_HAND]  =   "/esoui/art/inventory/inventory_tabicon_weapons_up.dds",
    [EQUIP_TYPE_NECK]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_OFF_HAND]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_ONE_HAND]  =   "/esoui/art/inventory/inventory_tabicon_weapons_up.dds",
    [EQUIP_TYPE_RING]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_SHOULDERS]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    [EQUIP_TYPE_TWO_HAND]  =   "/esoui/art/inventory/inventory_tabicon_weapons_up.dds",
    [EQUIP_TYPE_WAIST]  =   "/esoui/art/inventory/inventory_tabicon_armor_up.dds"
}

IIfA.gearslotTextures = {
    [EQUIP_TYPE_CHEST] = "/esoui/art/characterwindow/gearslot_chest.dds",
    [EQUIP_TYPE_COSTUME] = "/esoui/art/characterwindow/gearslot_costume.dds",
    [EQUIP_TYPE_FEET] = "/esoui/art/characterwindow/gearslot_feet.dds",
    [EQUIP_TYPE_HAND] = "/esoui/art/characterwindow/gearslot_hands.dds",
    [EQUIP_TYPE_HEAD] = "/esoui/art/characterwindow/gearslot_head.dds",
    [EQUIP_TYPE_LEGS] = "/esoui/art/characterwindow/gearslot_legs.dds",
    [EQUIP_TYPE_MAIN_HAND] = "/esoui/art/characterwindow/gearslot_mainhand.dds",
    [EQUIP_TYPE_NECK] = "/esoui/art/characterwindow/gearslot_neck.dds",
    [EQUIP_TYPE_OFF_HAND] = "/esoui/art/characterwindow/gearslot_offhand.dds",
    [EQUIP_TYPE_ONE_HAND] = "/esoui/art/characterwindow/gearslot_mainhand.dds",
    [EQUIP_TYPE_RING] = "/esoui/art/characterwindow/gearslot_ring.dds",
    [EQUIP_TYPE_SHOULDERS] = "/esoui/art/characterwindow/gearslot_shoulders.dds",
    [EQUIP_TYPE_TWO_HAND] = "/esoui/art/characterwindow/gearslot_mainhand.dds",
    [EQUIP_TYPE_WAIST] = "/esoui/art/characterwindow/gearslot_belt.dds",
    [15] = "/esoui/art/characterwindow/gearslot_tabard.dds"
}


function IIfA.IN2_ProcessItemAttribs( control, itemLink )
    local _modified = false
    if(control == IN2_ITEM_TOOLTIP or control == IN2_POPUP_TOOLTIP) then
        if(itemLink and itemLink ~= "") then
            --Use IN2_DissectItemLink() to get some attributes from link...
            local itemID,
            itemText,
            itemLevel,
            itemQuality,
            itemColor,
            itemStyle,
            itemType,
            itemEnchantmentType,
            itemEnchantmentStrength1,
            itemEnchantmentStrength2,
            itemIsBound,
            itemChargeStatus = IIfA.IN2_DissectItemLink(itemLink)
            --Then use ZO function to get the rest...
            local itemIcon,
            itemSellPrice,
            itemMeetsUsageRequirement,
            itemEquipType = GetItemLinkInfo(itemLink)
            -----------------------------------------------------------------------------------

            local raceTex = ""
            if(itemStyle and (tonumber(itemStyle) <= #IIfA.racialTextures)) then
                raceTex = IIfA.racialTextures[tonumber(itemStyle)].styleTexture
            end
            if(raceTex ~= "") then
                control.RaceIcon:SetTexture(raceTex)
                control.RaceIcon:SetAlpha(1)
                _modified = true
            else
                control.RaceIcon:SetTexture("")
                control.RaceIcon:SetAlpha(0)
            end

            local typeTex = ""
            if(itemEquipType and (tonumber(itemEquipType) <= #IIfA.itemEquipTypeTextures)) then
                typeTex = IIfA.itemEquipTypeTextures[tonumber(itemEquipType)]
            end
            if(typeTex ~= "") then
                control.TypeIcon:SetTexture(typeTex)
                control.TypeIcon:SetAlpha(1)
                _modified = true
            else
                control.TypeIcon:SetTexture("")
                control.TypeIcon:SetAlpha(0)
            end

            local styleName = ""
            if(itemStyle and (tonumber(itemStyle) <= #IIfA.racialTextures)) then
                styleName = IIfA.racialTextures[tonumber(itemStyle)].styleName
            end
            if(styleName ~= "") then
                control.StyleLabel:SetText(styleName)
                control.StyleLabel:SetHidden(false)
                _modified = true
            else
                control.StyleLabel:SetText("")
                control.StyleLabel:SetHidden(true)
            end

            IIfA.IN2_DebugOutput("itemStyle:"..itemStyle.." styleName:"..styleName.." racialTextures:"..raceTex)
        else
            IIfA.IN2_DebugOutput(control:GetName()..":Bad or no item link - can't process item attributes!")
        end
    end
    return _modified
end

function IIfA.IN2_IN2ToolTipShowHandler( control, ... )
	control.IN2_HasModified = false;
	if(control == IN2_ITEM_TOOLTIP) then
	    if control.animation then
	        control.animation:Stop()
	    end
	    control:SetAlpha(1)
		local mouseOverControl = moc();
		if(mouseOverControl ~= nil) then
            local mocParent = mouseOverControl:GetParent()
            if(mocParent)then
                if(mouseOverControl.dataEntry and mouseOverControl.dataEntry.data.bagId and mouseOverControl.dataEntry.data.slotIndex) then --is inventroy
                    local bag = mouseOverControl.dataEntry.data.bagId;
                    local index = mouseOverControl.dataEntry.data.slotIndex;
                    local curMouseOverLink = GetItemLink(bag, index, LINK_STYLE_BRACKETS);
                    --IIfA.IN2_HandleTooltipRAIntegration(bag, index, control)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink;
                elseif(mouseOverControl:GetParent():GetName() == "ZO_Character") then --is worn item
                    local bag = mouseOverControl.bagId
                    local index = mouseOverControl.itemIndex
                    local curMouseOverLink = GetItemLink(bag, index, LINK_STYLE_BRACKETS);
                    --IIfA.IN2_HandleTooltipRAIntegration(bag, index, control)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink
                elseif(mouseOverControl:GetParent():GetName() == "ZO_StoreWindowListContents") then --is store item
                    local curMouseOverLink = GetStoreItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink;
                elseif(mouseOverControl:GetParent():GetName() == "ZO_BuyBackListContents") then --is store item
                    local curMouseOverLink = GetBuybackItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink;
                elseif(mouseOverControl:GetParent():GetName() == "ZO_InteractWindowRewardArea") then --is store item
                    local curMouseOverLink = GetQuestRewardItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink;
                elseif(mouseOverControl:GetParent():GetName() == "ZO_LootAlphaContainerListContents") then --is loot item
                    local index = mouseOverControl.dataEntry.data.lootId;
                    local curMouseOverLink = GetLootItemLink(index, LINK_STYLE_BRACKETS)
                    IN2_CURRENT_MOUSEOVER_LINK = curMouseOverLink;
                end
            end
		end
	else --Control is IN2_POPUP_TOOLTIP
		control.lastLink = PopupTooltip.lastLink
	end
end


function IIfA.IN2_IN2ToolTipHideHandler( control, ... )
	control.IN2_HasModified = false;
	if(control == IN2_ITEM_TOOLTIP) then
		IN2_CURRENT_MOUSEOVER_LINK = nil;
        control.RaceIcon:SetTexture("")
        control.RaceIcon:SetAlpha(0)
        control.TypeIcon:SetTexture("")
        control.TypeIcon:SetAlpha(0)
        control.StyleLabel:SetText("")
        control.StyleLabel:SetHidden(true)
        control.IN2_Left = 0
        control.IN2_Top = 0
		--control.animation:Stop()
        control:ClearAnchors()
        control:SetAnchor(TOP, ItemTooltip, BOTTOM, 0, 0)

	end
    if(control == IN2_POPUP_TOOLTIP) then
        control.curAnchorPoint = BOTTOM
        control:ClearAnchors()
        control:SetAnchor(TOP, PopupTooltip, BOTTOM, 0, 0)
    end

	control:ClearLines()
end

function IIfA.IN2_AdjustTooltipPadding(control, minimal)
    local defaultX = 32
    local defaultY = 57
    if(control)then
        if(minimal)then
            control:SetResizeToFitPadding(32,17)
        else
            control:SetResizeToFitPadding(defaultX,defaultY)
        end
    end
end

function IIfA.IN2_CreateIN2ItemTooltipFrame()
    local ItemTooltip = ItemTooltip
	local height = 200
	local frame = WINDOW_MANAGER:CreateControlFromVirtual("IN2_ITEM_TOOLTIP", ItemTooltipTopLevel, "ItemTooltipBase")
    frame:ClearAnchors()
    frame:SetAnchor(TOP, ItemTooltip, BOTTOM, 0, 0)
    frame:SetDimensions(ItemTooltip:GetWidth(), height)
    frame.controlType = CT_CONTROL
    frame.system = SETTING_TYPE_UI
    frame:SetHidden(true)
    frame:SetMouseEnabled(false)
    frame:SetMovable(false)
    frame:SetClampedToScreen(true)

    IIfA.IN2_AdjustTooltipPadding(frame, IIfA.data.in2IN2TooltipsMinimalPadding)
    IIfA.IN2_AdjustTooltipPadding(ItemTooltip, IIfA.data.in2DefaultTooltipsMinimalPadding)

--[[
    ItemTooltip.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("TooltipFadeOutAnimation", ItemTooltip)
    ItemTooltip.animation:GetAnimation():GetTimeline():InsertCallback(function(...) IN2_ITEM_TOOLTIP.animation:PlayFromStart() end, 0)
    ItemTooltip.animation:GetAnimation():GetTimeline():InsertCallback(function(...) IN2_ITEM_TOOLTIP:SetHidden(true) end, 50)

    frame.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("TooltipFadeOutAnimation", frame)
    frame.animation:SetHandler("OnStop", function(animation)
        if animation:GetProgress() == 1.0 then
            frame:SetHidden(true)
		    frame:SetAlpha(1)
        end
    end)
--]]

    frame:SetHandler("OnShow", IIfA.IN2_IN2ToolTipShowHandler)
    frame:SetHandler("OnUpdate", function(...)
        local _modified = false
    	if((frame:GetLeft() ~= frame.IN2_Left) or (frame:GetTop() ~= frame.IN2_Top)) then
    		frame:ClearLines()
            IIfA.IN2_IN2ToolTipShowHandler(...)
		    local queryResults, processedAtribs = IIfA.IN2_TooltipUpdateHandler(...)
            --IIfA.IN2_AddWornItemControls( queryResults, frame)
            if(queryResults) then
                if(#queryResults.locations < 1) then
                    frame:AddLine(" ");
                    ZO_Tooltip_AddDivider(frame);
                else
                    _modified = true
                end
            end
            if(processedAtribs) then
                _modified = true
            end
		    frame.IN2_Left = frame:GetLeft()
	    	frame.IN2_Top = frame:GetTop()
            if(frame:GetTop() < ItemTooltip:GetBottom()) then
                frame:ClearAnchors()
                frame:SetAnchor(BOTTOM, ItemTooltip, TOP, 0, 0)
            end
            if(not _modified) then
                frame:SetHidden(true)
            end
	    end
	end)
    frame:SetHandler("OnHide", IIfA.IN2_IN2ToolTipHideHandler)


    frame.RaceIcon = WINDOW_MANAGER:CreateControl(frame:GetName().."RaceIcon", frame, CT_TEXTURE)
    frame.RaceIcon:SetDimensions(60,60)
    frame.RaceIcon:SetAnchor(TOPRIGHT, frame, TOPRIGHT, -2, 2)
    frame.RaceIcon:SetTexture("")
    frame.RaceIcon:SetTextureCoords(0,1,0,1)
    frame.RaceIcon:SetAlpha(0)

    frame.StyleLabel = WINDOW_MANAGER:CreateControl(frame:GetName().."StyleLabel", frame, CT_LABEL)
    local StyleLabel = frame.StyleLabel
    StyleLabel:SetAnchor(RIGHT, frame.RaceIcon, LEFT, -2, 0)
    StyleLabel:SetFont("ZoFontWinH4") -- ZoFontWinH4
    StyleLabel:SetText("")
    StyleLabel:SetHidden(true)

    frame.TypeIcon = WINDOW_MANAGER:CreateControl(frame:GetName().."TypeIcon", frame, CT_TEXTURE)
    frame.TypeIcon:SetDimensions(60,60)
    frame.TypeIcon:SetAnchor(TOPLEFT, frame, TOPLEFT, 2, 2)
    frame.TypeIcon:SetTexture("")
    frame.TypeIcon:SetTextureCoords(0,1,0,1)
    frame.TypeIcon:SetAlpha(0)


    frame.label = WINDOW_MANAGER:CreateControl(frame:GetName().."Label", frame, CT_LABEL)
    local label = frame.label
    --label:SetDimensions(290, 24)
    label:SetAnchor(TOP, frame, TOP, -50, 5)
    label:SetFont("ZoFontBookPaper") -- ZoFontWinH4
    label:SetText("-Inventory Insight From Ashes-")
    --label:SetHidden(true)

    return frame
end

function IIfA.IN2_CreateIN2PopupTooltipFrame()
    local PopupTooltip = PopupTooltip
	local height = 200
	local frame = WINDOW_MANAGER:CreateControlFromVirtual("IN2_POPUP_TOOLTIP", PopupTooltipTopLevel, "ItemTooltipBase")
    frame:ClearAnchors()
    frame:SetAnchor(TOP, PopupTooltip, BOTTOM, 0, 0)
    frame.curAnchorPoint = BOTTOM
    frame:SetDimensions(PopupTooltip:GetWidth(), height)
    frame.controlType = CT_CONTROL
    frame.system = SETTING_TYPE_UI
    frame:SetHidden(true)
    frame:SetMouseEnabled(false)
    frame:SetMovable(false)
    frame:SetClampedToScreen(true)

    IIfA.IN2_AdjustTooltipPadding(frame, IIfA.data.in2IN2TooltipsMinimalPadding)
    IIfA.IN2_AdjustTooltipPadding(PopupTooltip, IIfA.data.in2DefaultTooltipsMinimalPadding)

    frame:SetHandler("OnShow", IIfA.IN2_IN2ToolTipShowHandler)
    frame:SetHandler("OnUpdate", function(...)
        local _modified = false
    	if(frame.lastLink ~= PopupTooltip.lastLink) then
    		frame.IN2_HasModified = false
    		frame:ClearLines()
	    	frame.lastLink = PopupTooltip.lastLink
            local queryResults, processedAtribs = IIfA.IN2_TooltipUpdateHandler(...)
            if(queryResults) then
                if(#queryResults.locations < 1) then
                    frame:AddLine(" ");
                    ZO_Tooltip_AddDivider(frame);
                else
                    _modified = true
                end
            end
            if(processedAtribs) then
                _modified = true
            end
            if(not _modified) then
                frame:SetHidden(true)
            end
	    end
        if(frame.curAnchorPoint == BOTTOM and frame:GetTop() < PopupTooltip:GetBottom()) then
            frame.curAnchorPoint = TOP
            frame:ClearAnchors()
            frame:SetAnchor(BOTTOM, PopupTooltip, TOP, 0, 0)
        elseif(frame.curAnchorPoint == TOP and frame:GetBottom() > PopupTooltip:GetTop()) then
            frame.curAnchorPoint = BOTTOM
            frame:ClearAnchors()
            frame:SetAnchor(TOP, PopupTooltip, BOTTOM, 0, 0)
        end
	end)
    frame:SetHandler("OnHide", IIfA.IN2_IN2ToolTipHideHandler)

    frame.RaceIcon = WINDOW_MANAGER:CreateControl(frame:GetName().."RaceIcon", frame, CT_TEXTURE)
    frame.RaceIcon:SetDimensions(60,60)
    frame.RaceIcon:SetAnchor(TOPRIGHT, frame, TOPRIGHT, -2, 2)
    frame.RaceIcon:SetTexture("")
    frame.RaceIcon:SetTextureCoords(0,1,0,1)
    frame.RaceIcon:SetAlpha(0)

    frame.StyleLabel = WINDOW_MANAGER:CreateControl(frame:GetName().."StyleLabel", frame, CT_LABEL)
    local StyleLabel = frame.StyleLabel
    StyleLabel:SetAnchor(RIGHT, frame.RaceIcon, LEFT, -2, 0)
    StyleLabel:SetFont("ZoFontWinH4") -- ZoFontWinH4
    StyleLabel:SetText("")
    StyleLabel:SetHidden(true)

    frame.TypeIcon = WINDOW_MANAGER:CreateControl(frame:GetName().."TypeIcon", frame, CT_TEXTURE)
    frame.TypeIcon:SetDimensions(60,60)
    frame.TypeIcon:SetAnchor(TOPLEFT, frame, TOPLEFT, 2, 2)
    frame.TypeIcon:SetTexture("")
    frame.TypeIcon:SetTextureCoords(0,1,0,1)
    frame.TypeIcon:SetAlpha(0)

    frame.label = WINDOW_MANAGER:CreateControl(frame:GetName().."Label", frame, CT_LABEL)
    local label = frame.label
    --label:SetDimensions(290, 24)
    label:SetAnchor(TOP, frame, TOP, -50, 5)
    label:SetFont("ZoFontBookPaper") -- ZoFontWinH4
    label:SetText("-Inventory Insight From Ashes-")
    --label:SetHidden(true)

    return frame
end

