local IIfA = IIfA

function IIfA.IN2_DataToCSV()
	--build columns
	local Lines = {}
	local CSVData = "ItemName, Link, Bank"
	local characters = IIfA.IN2_CharacterInventories()
	local guilds = IIfA.IN2_GuildBanks()
	local all = { "Bank" }
	for x, character in pairs(characters)do
		table.insert(all, character)
		CSVData = CSVData..","..character
	end
	for x, guild in pairs(guilds)do
		table.insert(all, guild)
		CSVData = CSVData..", "..guild
	end
	Lines[0] = CSVData
	CSVData = ""
	--build lines
	local lineCount = 1
	local name, formattedName, uItem, itemCount = ""
    if(IIfA.data.DBv2)then
        for itemName, item in pairs(IIfA.data.DBv2) do
            name = item.attributes.itemName
            formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
            CSVData = formattedName -- ..", "..itemName
        	for x, location in pairs(all) do
        		uItem = item[location]
        		if(uItem) then
		        	itemCount = uItem.itemCount
		        	CSVData = CSVData..", count: "..itemCount
					--CSVData = CSVData..","..itemCount
		        else
		        	CSVData = CSVData.."0"
		        end
	        end
			Lines[lineCount] = CSVData
			CSVData = ""
			lineCount = lineCount + 1
        end
    end

	IIfA.data.CSVData = {}
	IIfA.data.CSVData.CollectedDate = GetDate()
	IIfA.data.CSVData.Lines = Lines
end


--[[
function IIfA.IN2_DataToCSV_OLD()
	 local CSVData = "Location,Link,Count"
	 if(#IIfA.data.bankBag.items > 0) then
		 for x, bankItem in pairs(IIfA.data.bankBag.items) do
			 CSVData = CSVData.."\nBank,"..bankItem.link..","..bankItem.itemCount
		 end
	 end
	 if(IIfA.data.guildBanks) then
		 for guildName, guild in pairs(IIfA.data.guildBanks) do
			 for i, guildBankItem in pairs(guild.items) do
				 CSVData = CSVData.."\n"..guildName..","..guildBankItem.link..","..guildBankItem.itemCount
			 end
		 end
	 end
	 if(#IIfA.data.accountCharacters > 0) then
		 for x, character in pairs(IIfA.data.accountCharacters) do
			 for i, characterItem in pairs(character.bag.items) do
				 CSVData = CSVData.."\n"..character.characterName..","..characterItem.link..","..characterItem.itemCount
			 end
		 end
	 end
	 IIfA.data.CSVData = CSVData
end


function IIfA.IN2_CreateOrShowExportFrame()
	 if(IN2_ExportCSVDataTLC)then
		 IN2_ExportCSVDataTLC:SetHidden(false)
		 IN2_ExportCSVDataFrame:SetHidden(false)
	 else
		 controlName = "IN2_ExportCSVDataFrame"

		 local ExportTLC = WINDOW_MANAGER:CreateTopLevelWindow("IN2_ExportCSVDataTLC")
	     ExportTLC:SetAnchor(CENTER)
	     ExportTLC:SetDimensions(700, 600)

	     local frame = WINDOW_MANAGER:CreateControlFromVirtual(controlName, ExportTLC, "ZO_DefaultBackdrop")
	     frame:ClearAnchors()
	     frame:SetAnchor(CENTER, ExportTLC, CENTER, 0, 0) --ZO_SharedThinLeftPanelBackground anchor
	     frame:SetDimensions(750, 400)
	     frame.controlType = CT_CONTROL
	     frame.system = SETTING_TYPE_UI
	     frame:SetHidden(false)
	     frame:SetMouseEnabled(true)
	     frame:SetMovable(true)
	     frame:SetClampedToScreen(true)

	     frame:SetHandler("OnShow", function(...)
	    		 local outDatedGuilds = IIfA.IN2_CheckForAgedGuildBankData(1)
	    		 if(outDatedGuilds)then
	    			 frame.warningLabel:SetHidden(false)
	    		 else
	    			 frame.warningLabel:SetHidden(true)
	    		 end
	    	 end)

	     frame.CloseFrame = IIfA.IN2_ExportFrameCloseWindow(frame)

	     frame.label = WINDOW_MANAGER:CreateControl(controlName.."Label", frame, CT_LABEL)
	     local label = frame.label
	     label:SetAnchor(TOP, frame, TOP, 0, 2)
	     label:SetMouseEnabled(false)
	     label:SetFont("ZoFontWinH4")
	     label:SetText("-INVENTORY INSIGHT-")
	     label:SetColor(.772,.760,.619,1)

	     frame.warningLabel = WINDOW_MANAGER:CreateControl(controlName.."warningLabel", frame, CT_LABEL)
	     local warningLabel = frame.warningLabel
	     warningLabel:SetAnchor(TOP, frame, TOP, 10, 25)
	     warningLabel:SetMouseEnabled(false)
	     warningLabel:SetFont("ZoFontWinH4")
	     warningLabel:SetText("[WARNING] - Your guild bank data appears to be out of date!")
	     warningLabel:SetColor(1,0,0,1)
		 local outDatedGuilds = IIfA.IN2_CheckForAgedGuildBankData(1)
		 if(outDatedGuilds)then
			 frame.warningLabel:SetHidden(false)
		 else
			 frame.warningLabel:SetHidden(true)
		 end

	     frame.exportCSVDataLbl = WINDOW_MANAGER:CreateControl(controlName.."exportCSVDataLbl", frame, CT_LABEL)
	     local exportCSVDataLbl = frame.exportCSVDataLbl
	     exportCSVDataLbl:SetAnchor(TOPLEFT, frame, TOPLEFT, 10, 50)
	     exportCSVDataLbl:SetMouseEnabled(false)
	     exportCSVDataLbl:SetFont("ZoFontWinH4")
	     exportCSVDataLbl:SetText("1. Export collected item data into CSV formatted table.")

	     frame.exportCSVDataBtn = WINDOW_MANAGER:CreateControlFromVirtual("ExportCSVDataBtnButton", frame, "ZO_DefaultButton")
		 local exportCSVDataBtn = frame.exportCSVDataBtn
		 exportCSVDataBtn:SetAnchor(TOPLEFT, exportCSVDataLbl, BOTTOMLEFT, 20, 5)
		 exportCSVDataBtn:SetWidth(250)
		 exportCSVDataBtn:SetText("Export CSV Data")
		 exportCSVDataBtn:SetHandler("OnClicked", IIfA.IN2_DataToCSV)


	     frame.reloadUILbl = WINDOW_MANAGER:CreateControl(controlName.."reloadUILbl", frame, CT_LABEL)
	     local reloadUILbl = frame.reloadUILbl
	     reloadUILbl:SetAnchor(TOPLEFT, exportCSVDataBtn, BOTTOMLEFT, -20, 5)
	     reloadUILbl:SetMouseEnabled(false)
	     reloadUILbl:SetFont("ZoFontWinH4")
	     reloadUILbl:SetText("2. Reload the UI to save the saved CSV table to an external file.")

	     frame.reloadUIBtn = WINDOW_MANAGER:CreateControlFromVirtual("ExportReloadUIBtnButton", frame, "ZO_DefaultButton")
		 local reloadUIBtn = frame.reloadUIBtn
		 reloadUIBtn:SetAnchor(TOPLEFT, reloadUILbl, BOTTOMLEFT, 20, 5)
		 reloadUIBtn:SetWidth(200)
		 reloadUIBtn:SetText("ReloadUI")
		 reloadUIBtn:SetHandler("OnClicked", function(...) ReloadUI("ingame") end)


	     frame.gotoWebSiteLbl = WINDOW_MANAGER:CreateControl(controlName.."gotoWebSite", frame, CT_LABEL)
	     local gotoWebSiteLbl = frame.gotoWebSiteLbl
	     gotoWebSiteLbl:SetAnchor(TOPLEFT, reloadUIBtn, BOTTOMLEFT, -20, 5)
	     gotoWebSiteLbl:SetMouseEnabled(false)
	     gotoWebSiteLbl:SetFont("ZoFontWinH4")
	     gotoWebSiteLbl:SetText("3. Goto the following webiste.")

	     frame.website = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."gotoWebSiteBG", frame, "ZO_EditBackdrop")
	     local website = frame.website
	     website:SetDimensions(500,24)
	     website:SetAnchor(TOPLEFT, gotoWebSiteLbl, BOTTOMLEFT, 20, 5)
		 website.edit = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."gotoWebSiteEdit", website, "ZO_DefaultEditForBackdrop")
		 website.edit:SetText("http://www.vicsterscafe.com/parser.php")
		 website.edit:SetEditEnabled(false)

	     frame.savedVariablesLocationLbl = WINDOW_MANAGER:CreateControl(controlName.."savedVariablesLocation", frame, CT_LABEL)
	     local savedVariablesLocationLbl = frame.savedVariablesLocationLbl
	     savedVariablesLocationLbl:SetAnchor(TOPLEFT, website, BOTTOMLEFT, -20, 5)
	     savedVariablesLocationLbl:SetMouseEnabled(false)
	     savedVariablesLocationLbl:SetFont("ZoFontWinH4")
	     savedVariablesLocationLbl:SetText("4. Click 'Choose File' on the web page and browse to the saved file at the following location\n (PC or Mac). Then click 'upload'.")

	     frame.savedVariablesLocationPC = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."savedVariablesLocationPCBG", frame, "ZO_EditBackdrop")
	     local savedVariablesLocationPC = frame.savedVariablesLocationPC
	     savedVariablesLocationPC:SetDimensions(700,50)
	     savedVariablesLocationPC:SetAnchor(TOPLEFT, savedVariablesLocationLbl, BOTTOMLEFT, 20, 5)
		 savedVariablesLocationPC.edit = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."savedVariablesLocationPCEdit", savedVariablesLocationPC, "ZO_DefaultEditForBackdrop")
		 savedVariablesLocationPC.edit:SetText("PC - %UserProfile%\\Documents\\Elder Scrolls Online\\live\\SavedVariables\\IIfA.lua")
		 savedVariablesLocationPC.edit:SetEditEnabled(false)

		 frame.savedVariablesLocationMac = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."savedVariablesLocationMacBG", frame, "ZO_EditBackdrop")
	     local savedVariablesLocationMac = frame.savedVariablesLocationMac
	     savedVariablesLocationMac:SetDimensions(700,50)
	     savedVariablesLocationMac:SetAnchor(TOPLEFT, savedVariablesLocationPC, BOTTOMLEFT, 0, 5)
		 savedVariablesLocationMac.edit = WINDOW_MANAGER:CreateControlFromVirtual(controlName.."savedVariablesLocationMacEdit", savedVariablesLocationMac, "ZO_DefaultEditForBackdrop")
		 savedVariablesLocationMac.edit:SetText("Mac - ~/Documents/Elder Scrolls Online/<build flavor>/SavedVariables/IIfA.lua")
		 savedVariablesLocationMac.edit:SetEditEnabled(false)
	 end
end

function IIfA.IN2_ExportFrameCloseWindow( parent )
     if(parent) then
         local CloseFrame = WINDOW_MANAGER:CreateControl(parent:GetName().."FrameClose",parent,CT_CONTROL)
         CloseFrame:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -5, 5)
         CloseFrame:SetMouseEnabled(false)
         CloseFrame:SetInheritAlpha(false)
         CloseFrame:SetDimensions(40,20)

         CloseFrame.icon = WINDOW_MANAGER:CreateControl(nil,CloseFrame,CT_TEXTURE)
         CloseFrame.icon:SetDimensions(20,20)
         CloseFrame.icon:SetAnchor(RIGHT, CloseFrame, RIGHT, 0, 0)
         CloseFrame.icon:SetTexture("/esoui/art/buttons/decline_up.dds")
         CloseFrame.icon:SetTextureCoords(0,1,0,1)
         CloseFrame.icon:SetAlpha(1)
         CloseFrame.icon:SetMouseEnabled(true)

         CloseFrame.icon:SetHandler("OnMouseEnter",function(self)
             CloseFrame.over:SetAlpha(1)
         end)
         CloseFrame.icon:SetHandler("OnMouseExit",function(self)
             CloseFrame.over:SetAlpha(0)
         end)
         CloseFrame.icon:SetHandler("OnMouseDown",function(self)
             CloseFrame.icon:SetTexture("/esoui/art/buttons/decline_down.dds")
         end)
         CloseFrame.icon:SetHandler("OnMouseUp",function(self)
             CloseFrame.icon:SetTexture("/esoui/art/buttons/decline_up.dds")
             parent:SetHidden(true)
             CloseFrame.over:SetAlpha(0)
         end)

         CloseFrame.over = WINDOW_MANAGER:CreateControl(nil,CloseFrame,CT_TEXTURE)
         CloseFrame.over:SetDimensions(20,20)
         CloseFrame.over:SetAnchor(RIGHT, CloseFrame, RIGHT, 0, 0)
         CloseFrame.over:SetTexture("/esoui/art/buttons/decline_over.dds")
         CloseFrame.over:SetTextureCoords(0,1,0,1)
         CloseFrame.over:SetAlpha(0)

    	return CloseFrame
   	end
end
--]]
