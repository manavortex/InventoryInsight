--[[
-- 03.06.2018, Baertram
-- Plugin for the addon FCOItemSaver (http://www.esoui.com/downloads/info630-FCOItemSaver.html)
-- Add functions to be able to show the FCOIS marker icons at the IIfA inventory frame rows e.g.
 ]]

--Constant value used within the functions below and within function "FCOIS.GetItemSaverControl()" in file FCOitemSaver/FCOIS_Functions.lua
--to build a unique texture name for the FCOIS marker icon CT_TEXTURE controls
FCOIS_IIfA_TEXTURE_CONTROL_NAME = "_IIfA_"

--Only do if FCOItemSaver is loaded
if FCOIS == nil or FCOIS.MyGetItemInstanceIdForIIfA == nil then return false end
local addonName = FCOIS.addonVars.gAddonName
local numVars = FCOIS.numVars
local markerTextureVars = FCOIS.textureVars.MARKER_TEXTURES

local getItemSaverControl = FCOIS.GetItemSaverControl
local myGetItemInstanceIdForIIfA = FCOIS.MyGetItemInstanceIdForIIfA
local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local createToolTip = FCOIS.CreateToolTip

local WM = WINDOW_MANAGER

--[[
-- Create the textures for the FCOIS marker icons at the IIfA inventory frame rows and load the texture's .dds files
-- to them accordingly to the FCOIS settings and show them
-- Parameters:
--> curLine (control):                          The current line inside the IIfA inventory frame (= row to update). See file IIfABackpack.lua, function fillLine(curLine, curItem)
--> showFCOISMarkerIcons (boolean):             [true= Show the texture controls / false= Hide the texture controls]
--> createFCOISMarkerIcons (boolean|nilable):   [true= Create the texture controls if not already there/ false= Do not create the texture controls]. Can be nil and will be set to false then
--> iconId (integer or table|nilable):          Integer (icon Id or -1 for all) or a table which contains the FCOIS marker icons to create the textures for. Can be nil = Process "all" marker icon textures.
---> integer or table: key = integer or string, value = iconId (can be a number or the constant from the addon FCOItemSaver file FCOIS_Constants.lua, e.g. FCOIS_CON_ICON_LOCK, ...
--      iconIds = {
--          [1] = 1,
--          ["test"] = FCOIS_CON_ICON_GEAR_1,
--          [3] = 3,
--      }
]]
function IIfA:UpdateFCOISMarkerIcons(curLine, showFCOISMarkerIcons, createFCOISMarkerIcons, iconId)
  --d("[IIfA]UpdateFCOISMarkerIcons - curLine: " ..tostring(curLine:GetName()) .. ", showFCOISMarkerIcons: " .. tostring(showFCOISMarkerIcons) .. ", createFCOISMarkerIcons: " ..tostring(createFCOISMarkerIcons))
  if curLine == nil or showFCOISMarkerIcons == nil then return false end
  createFCOISMarkerIcons = createFCOISMarkerIcons or false

  --Needed settings, number and mapping variables
  local settings = FCOIS.settingsVars.settings
  local numFilterIcons = numVars.gFCONumFilterIcons

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
  local iconSettings = settings.icon

  --------------------------------------------------------------------------------------------------------------------
  --Function to create the texture control CT_TEXTURE now and anchor it to the parent's line
  --------------------------------------------------------------------------------------------------------------------
  local function UpdateAndAnchorMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pCreateControlIfNotThere, pHideControl)
    --No parent? Abort here
    if parent == nil then return nil end
    pCreateControlIfNotThere = pCreateControlIfNotThere or false

    --Does the FCOItemSaver marker control exist already? -> Respecting the constant  in the control name by passing it as a parameter!
    local control = getItemSaverControl(parent, markerIconId, false, FCOIS_IIfA_TEXTURE_CONTROL_NAME)
    local doHide = pHideControl

    --Should the control shown (not hidden)? Then check it's marker settings and if a marker is set
    if not doHide then
      --Marker control for a disabled icon? Hide the icon then
      if not settings.isIconEnabled[markerIconId] then
        --Do not hide the texture and do not create it to save memory
        return nil
      else
        --Control should be shown
        --Get the data of the currentLine and check by help of the itemInstanceId if the item should be marked
        --itemInstanceOrUniqueId, bagId, slotIndex, itemFoundAtLocationTableCharactersAndWornBag, itemFoundAtLocationTableAllOtherBags = FCOIS.MyGetItemInstanceIdForIIfA(control, signItemInstanceOrUniqueId)
        local itemInstanceOrUniqueId = myGetItemInstanceIdForIIfA(parent, false)
        local isItemProtectedWithMarkerIcon = checkIfItemIsProtected(markerIconId, itemInstanceOrUniqueId)
        --Hide the control if the item is not protected
        doHide = not isItemProtectedWithMarkerIcon
      end
    end
    if doHide == nil then doHide = false end

    --Control for marker icon does not exist yet, so create it now
    if (control == parent or control == nil) then
      --Abort here if control should be hidden and is not created yet
      if doHide == true and pCreateControlIfNotThere == false then
        ZO_Tooltips_HideTextTooltip()
        return
      end
      --If not aborted: Create the marker control now
      --Important: Add the constant FCOIS_IIfA_TEXTURE_CONTROL_NAME to the name for textures created within IIfA inventory frame!
      control = WM:CreateControl(parent:GetName() .. addonName .. FCOIS_IIfA_TEXTURE_CONTROL_NAME .. tostring(markerIconId), parent, CT_TEXTURE)
    end
    --Control did already exist or was created
    if control ~= nil then
      --Hide or show the control now
      control:SetHidden(doHide)
      --Should the control not be hidden (should be shown shown)?
      if not doHide then
        --Update the dimensions, texture file etc.
        control:SetDimensions(pWidth, pHeight)
        control:SetTexture(pTexture)
        local iconSettingsColor = settings.icon[markerIconId].color
        control:SetColor(iconSettingsColor.r, iconSettingsColor.g, iconSettingsColor.b, iconSettingsColor.a)
        control:SetDrawTier(DT_HIGH)
        control:ClearAnchors()
        --local iconOffset = settings.iconPosition
        --control:SetAnchor(LEFT, parent, LEFT, iconOffset.x, iconOffset.y)
        control:SetAnchor(TOPRIGHT, parent, TOPLEFT, 0, 0)
        --Set the tooltip if wished
        if createToolTip ~= nil then
          --Set the "calledByExternalAddon" flag to "IIfA"
          -->See file AddOns/FCOItemSaver/FCOIS_MarkerIcons.lua
          --Check if item is worn and/or stolen and add the text to the FCOIS tooltip!
          --d("stolen hidden: " ..tostring(parent.stolen:IsHidden()) .. " worn hidden: " ..tostring(parent.worn:IsHidden()))
          local stolenVal = parent.stolen
          local wornVal = parent.worn
          local isStolen = (stolenVal ~= nil and not stolenVal:IsHidden()) or false
          local isWorn = (wornVal ~= nil and not wornVal:IsHidden()) or false
          --d("stolen: " ..tostring(isStolen) .. " worn: " ..tostring(isWorn))
          local stolenTTText = ""
          local wornTTText = ""
          local addTTText = ""
          if isStolen then
            stolenTTText = GetString(SI_INVENTORY_STOLEN_ITEM_TOOLTIP) --Stolen item
          end
          if isWorn then
            wornTTText = GetString(SI_CHARACTER_EQUIP_TITLE) --Equipped
          end
          if stolenTTText ~= "" then
            addTTText = stolenTTText
          end
          if wornTTText ~= "" then
            if addTTText ~= "" then
              addTTText = addTTText .. "\n" .. wornTTText
            else
              addTTText = wornTTText
            end
          end
          createToolTip(control, markerIconId, doHide, false, false, "IIfA", addTTText)
        end
      end  -- if not doHide then
      return control
    else
      return nil
    end
  end
  --------------------------------------------------------------------------------------------------------------------

  --Create FCOItemSaver marker texture controls in IIfA inventory frame (at current row) for each FCOIS marker icon ID in iconsToCheck
  for _, markerIconId in ipairs(iconsToCheck) do
    local iconSettingsOfMarkerIcon = iconSettings[markerIconId]
    local iconSize = iconSettingsOfMarkerIcon.size
    UpdateAndAnchorMarkerControl(curLine, markerIconId, iconSize, iconSize, markerTextureVars[iconSettingsOfMarkerIcon.texture], createFCOISMarkerIcons, not showFCOISMarkerIcons)
  end
end
