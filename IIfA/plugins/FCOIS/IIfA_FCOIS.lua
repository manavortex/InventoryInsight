--[[
-- 03.06.2018, Baertram
-- Plugin for the addon FCOItemSaver (http://www.esoui.com/downloads/info630-FCOItemSaver.html)
-- Add functions to be able to show the FCOIS marker icons at the IIfA inventory frame rows e.g.
 ]]

--Constant value used within the functions below and within function "FCOIS.GetItemSaverControl()" in file FCOitemSaver/FCOIS_Functions.lua
--to build a unique texture name for the FCOIS marker icon CT_TEXTURE controls
FCOIS_IIfA_TEXTURE_CONTROL_NAME = "_IIfA_"

--[[
-- Create the textures for the FCOIS marker icons at the IIfA inventory frame rows and load the texture's .dds files
-- to them accordingly to the FCOIS settings and show them
-- Parameters:
--> curLine (control):                          The current line inside the IIfA inventory frame (= row to update). See file IIfABackpack.lua, function fillLine(curLine, curItem)
--> showFCOISMarkerIcons (boolean):             [true= Show the texture controls / false= Hide the texture controls]
--> createFCOISMarkerIcons (boolean|nilable):   [true= Create the texture controls if not already there/ false= Do not create the texture controls]. Can be nil and will be set to false then
--> iconId (integer or table|nilable):          Integer (icon Id or -1 for all) or a table which contains the FCOIS marker icons to create the textures for. Can be nil = Process "all" marker icon textures.
---> integer or table: key = integer or string, value = iconId (can be a number or the constant from the addon FCOItemSaver file FCOIS_Constants.lua, e.g. FCOIS_CON_ICON_LOCK ...
--      iconIds = {
--          [1] = 1,
--          ["test"] = FCOIS_CON_ICON_GEAR_1,
--          [3] = 3,
--      }
]]
function IIfA:UpdateFCOISMarkerIcons(curLine, showFCOISMarkerIcons, createFCOISMarkerIcons, iconId)
--d("[IIfA]UpdateFCOISMarkerIcons - curLine: " ..tostring(curLine:GetName()) .. ", showFCOISMarkerIcons: " .. tostring(showFCOISMarkerIcons) .. ", createFCOISMarkerIcons: " ..tostring(createFCOISMarkerIcons))
    --Only do if FCOItemSaver is loaded
    if FCOIS == nil then return false end
    if curLine == nil or showFCOISMarkerIcons == nil then return false end
    createFCOISMarkerIcons = createFCOISMarkerIcons or false

    --Needed settings, number and mapping variables
    local settings = FCOIS.settingsVars.settings
    local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

    local iconsToCheck = {}
    --Check the iconId parameter, integer or table?
    if type(iconId) == "table" then
        --Transfer the iconIds to a sorted table
        for _, FCOISmarkerIconId in pairs(iconId) do
            table.insert(iconsToCheck, FCOISmarkerIconId)
        end
    elseif type(iconId) == "number" then
        --iconId is too high or too low and not -1 (for all icons)?
        if ((iconId > numFilterIcons) or (iconId < 1 and iconId ~= -1)) then return false end
        if iconId == -1 then
            --Add all marker icons to the check table
            for FCOISmarkerIconId = 1, numFilterIcons, 1 do
                table.insert(iconsToCheck, FCOISmarkerIconId)
            end
        else
            --Add only the given marker icon id to the check table
            table.insert(iconsToCheck, iconId)
        end
    else
        --Not supported parameter value
        return false
    end
    if iconsToCheck ~= nil and #iconsToCheck > 0 then
        --Sort the icons to check table ascending by the icon Id now
        table.sort(iconsToCheck)
    else
        return false
    end
    local iconSettings = FCOIS.settingsVars.settings.icon
    local markerTextureVars = FCOIS.textureVars.MARKER_TEXTURES

    --Function to create the texture control CT_TEXTURE now and anchor it to the parent's line
    local function UpdateAndAnchorMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pCreateControlIfNotThere, pHideControl)
        --No parent? Abort here
        if parent == nil then return nil end
        pCreateControlIfNotThere = pCreateControlIfNotThere or false

        --Does the FCOItemSaver marker control exist already? -> Respecting the constant  in the control name by passing it as a parameter!
        local control = FCOIS.GetItemSaverControl(parent, markerIconId, false, FCOIS_IIfA_TEXTURE_CONTROL_NAME)
        local doHide = pHideControl

        --Should the control not be hidden? Then check it's marker settings and if a marker is set
        if not doHide then
            --Marker control for a disabled icon? Hide the icon then
            if not settings.isIconEnabled[markerIconId] then
                --Do not hide the texture anymore but do not create it to save memory
                --doHide = true
                return false
            else
                --Control should be shown
                local itemInstanceOrUniqueId, bagId, slotIndex = FCOIS.MyGetItemInstanceIdForIIfA(parent, false)
                local isItemProtectedWithMarkerIcon = FCOIS.checkIfItemIsProtected(markerIconId, itemInstanceOrUniqueId)
                doHide = not isItemProtectedWithMarkerIcon
            end
        end
        if doHide == nil then doHide = false end

        --It does not exist yet, so create it now
        if(control == parent or not control) then
            --Abort here if control should be hiden and is not created yet
            if doHide == true and pCreateControlIfNotThere == false then
                ZO_Tooltips_HideTextTooltip()
                return
            end
            --If not aborted: Create the marker control now
            local addonName = FCOIS.addonVars.gAddonName
            --Important: Add the constant FCOIS_IIfA_TEXTURE_CONTROL_NAME to the name for textures created within IIfA inventory frame!
            control = WINDOW_MANAGER:CreateControl(parent:GetName() .. addonName .. FCOIS_IIfA_TEXTURE_CONTROL_NAME .. tostring(markerIconId), parent, CT_TEXTURE)
        end
        --Control did already exist or was created now
        if control ~= nil then
            --Hide or show the control now
            control:SetHidden(doHide)

            if not doHide then
                control:SetDimensions(pWidth, pHeight)
                control:SetTexture(pTexture)
                local iconSettingsColor = settings.icon[markerIconId].color
                control:SetColor(iconSettingsColor.r, iconSettingsColor.g, iconSettingsColor.b, iconSettingsColor.a)
                control:SetDrawTier(DT_HIGH)
                control:ClearAnchors()
                local iconOffset = settings.iconPosition
                --control:SetAnchor(LEFT, parent, LEFT, iconOffset.x, iconOffset.y)
                control:SetAnchor(TOPRIGHT, parent, TOPLEFT, 0, 0)
                --<Anchor point="TOPRIGHT" relativeTo="$(parent)Button" relativePoint="TOPLEFT" />

            end  -- if not doHide then
            --Set the tooltip if wished
            if FCOIS.CreateToolTip ~= nil then
                --Set the "calledByExternalAddon" flag to "IIfA"
                FCOIS.CreateToolTip(control, markerIconId, doHide, false, false, "IIfA")
            end
            return control
        else
            return nil
        end
    end

    --Create textures in IIfA inventory frame for each marker icon ID in iconsToCheck
    for _, markerIconId in ipairs(iconsToCheck) do
        UpdateAndAnchorMarkerControl(curLine, markerIconId, iconSettings[markerIconId].size, iconSettings[markerIconId].size, markerTextureVars[iconSettings[markerIconId].texture], createFCOISMarkerIcons, not showFCOISMarkerIcons)
    end
end