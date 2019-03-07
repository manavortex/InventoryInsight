local CharCurrencyFrame = ZO_Object:Subclass()
if IIfA == nil then IIfA = {} end
IIfA.CharCurrencyFrame = CharCurrencyFrame

local g_currenciesData = ZO_CURRENCIES_DATA
local function GetCurrencyColor(currencyType)
	return g_currenciesData[currencyType].color
end

function CharCurrencyFrame:SetQty(control, field, fieldType, qty, saveWidthType)
	local ctl = control:GetNamedChild(field)

	if qty == nil then
		qty = 0
	end

	local formattedAmt = ZO_CurrencyControl_FormatCurrency(qty)
	local textWidth = ctl:GetStringWidth(formattedAmt) / GetUIGlobalScale()
	if textWidth > self.maxWidths[saveWidthType][field] then
		self.maxWidths[saveWidthType][field] = textWidth
	end
	ctl:SetText(GetCurrencyColor(fieldType):Colorize(formattedAmt))
end

function CharCurrencyFrame:UpdateAssets()
	if self.currAssets ~= nil then
		self.currAssets.gold = GetCarriedCurrencyAmount(CURT_MONEY)
		self.currAssets.tv = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
		self.currAssets.ap = GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS)
		self.currAssets.wv = GetCarriedCurrencyAmount(CURT_WRIT_VOUCHERS)
	end
end

function CharCurrencyFrame:FillCharAndBank()
	self:UpdateAssets()

	local gold = self.currAssets.gold
	local tv = self.currAssets.tv
	local ap = self.currAssets.ap
	local wv = self.currAssets.wv

	self.maxWidths["Self"]["qtyGold"] = 9
	self.maxWidths["Self"]["qtyTV"] = 9
	self.maxWidths["Self"]["qtyAP"] = 9
	self.maxWidths["Self"]["qtyWV"] = 9

	self:SetQty(self.charControl, "qtyGold", CURT_MONEY, gold, "Self")
	self:SetQty(self.charControl, "qtyTV", CURT_TELVAR_STONES, tv, "Self")
	self:SetQty(self.charControl, "qtyAP", CURT_ALLIANCE_POINTS, ap, "Self")
	self:SetQty(self.charControl, "qtyWV", CURT_WRIT_VOUCHERS, wv, "Self")

	local bankedMoney = GetBankedCurrencyAmount(CURT_MONEY)
	local bankedTelVarStones = GetBankedCurrencyAmount(CURT_TELVAR_STONES)
	local bankedAlliancePoints = GetBankedCurrencyAmount(CURT_ALLIANCE_POINTS)
	local bankedWritVouchers = GetBankedCurrencyAmount(CURT_WRIT_VOUCHERS)

	self:SetQty(self.bankControl, "qtyGold", CURT_MONEY, bankedMoney, "Self")
	self:SetQty(self.bankControl, "qtyTV", CURT_TELVAR_STONES, bankedTelVarStones, "Self")
	self:SetQty(self.bankControl, "qtyAP", CURT_ALLIANCE_POINTS, bankedAlliancePoints, "Self")
	self:SetQty(self.bankControl, "qtyWV", CURT_WRIT_VOUCHERS, bankedWritVouchers, "Self")

	gold = gold + bankedMoney + self.totGold
	tv = tv + bankedTelVarStones + self.totTV
	ap = ap + bankedAlliancePoints + self.totAP
	wv = wv + bankedWritVouchers + self.totWV

	self:SetQty(self.totControl, "qtyGold", CURT_MONEY, gold, "Self")
	self:SetQty(self.totControl, "qtyTV", CURT_TELVAR_STONES, tv, "Self")
	self:SetQty(self.totControl, "qtyAP", CURT_ALLIANCE_POINTS, ap, "Self")
	self:SetQty(self.totControl, "qtyWV", CURT_WRIT_VOUCHERS, wv, "Self")

	local key, width
	for key, width in pairs(self.maxWidths["Self"]) do
		if self.maxWidths["Others"][key] > width then
			self.maxWidths["Self"][key] = width
		end
	end

	local ctr, control, ctl
	local padding = 13
	for ctr, control in pairs(self.controls) do
		for key, width in pairs(self.maxWidths["Self"]) do
			ctl = control:GetNamedChild(key)
			ctl:SetWidth(width + padding)
		end
	end

	padding = padding + 6
	ctl = self.frame:GetNamedChild("icon_qtyGold")
	ctl:ClearAnchors()
	ctl:SetAnchor(TOPRIGHT, self.frame:GetNamedChild("_TitleCharName"), TOPRIGHT, self.maxWidths["Self"]["qtyGold"] + padding, 0)
	ctl = self.frame:GetNamedChild("icon_qtyTV")
	ctl:ClearAnchors()
	ctl:SetAnchor(TOPRIGHT, self.frame:GetNamedChild("icon_qtyGold"), TOPRIGHT, self.maxWidths["Self"]["qtyTV"] + padding, 0)
	ctl = self.frame:GetNamedChild("icon_qtyAP")
	ctl:ClearAnchors()
	ctl:SetAnchor(TOPRIGHT, self.frame:GetNamedChild("icon_qtyTV"), TOPRIGHT, self.maxWidths["Self"]["qtyAP"] + padding, 0)
	ctl = self.frame:GetNamedChild("icon_qtyWV")
	ctl:ClearAnchors()
	ctl:SetAnchor(TOPRIGHT, self.frame:GetNamedChild("icon_qtyAP"), TOPRIGHT, self.maxWidths["Self"]["qtyWV"] + padding, 0)
	self.frame:SetWidth(self.totControl:GetWidth() + 3)

-- field width testing
--	self:SetQty(self.totControl, "qtyGold", CURT_MONEY, 99999999)
--	self:SetQty(self.totControl, "qtyTV", CURT_TELVAR_STONES, 99999999)
--	self:SetQty(self.totControl, "qtyAP", CURT_ALLIANCE_POINTS, 99999999)
--	self:SetQty(self.totControl, "qtyWV", CURT_WRIT_VOUCHERS, 99999999)
end


function CharCurrencyFrame:Initialize(objectForAssets)
	self.frame = IIFA_CharCurrencyFrame
	self.maxWidths = {}
	self.maxWidths["Self"] = {["qtyGold"] = 9, ["qtyTV"] = 9, ["qtyAP"] = 9, ["qtyWV"] = 9}	-- maximum widths of all the data from current char
	self.maxWidths["Others"] = {["qtyGold"] = 9, ["qtyTV"] = 9, ["qtyAP"] = 9, ["qtyWV"] = 9}	-- maximum widths of all the data from other chars
	self.controls = {}
	local tControl
	local prevControl = self.frame
	local currId = GetCurrentCharacterId()
	local i
	local charNameMaxWidth = 0
	local charNameWidth

	local iconSize = 18
	prevControl:GetNamedChild("icon_qtyGold"):SetTexture(GetCurrencyKeyboardIcon(CURT_MONEY))
	prevControl:GetNamedChild("icon_qtyGold"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("icon_qtyTV"):SetTexture(GetCurrencyKeyboardIcon(CURT_TELVAR_STONES))
	prevControl:GetNamedChild("icon_qtyTV"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("icon_qtyAP"):SetTexture(GetCurrencyKeyboardIcon(CURT_ALLIANCE_POINTS))
	prevControl:GetNamedChild("icon_qtyAP"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("icon_qtyWV"):SetTexture(GetCurrencyKeyboardIcon(CURT_WRIT_VOUCHERS))
	prevControl:GetNamedChild("icon_qtyWV"):SetDimensions(iconSize, iconSize)

	if objectForAssets.assets == nil then
		objectForAssets.assets = {}
	end
	local assets = objectForAssets.assets

	if assets[currId] == nil then
		assets[currId] = {}
		assets[currId].gold = 0
		assets[currId].tv = 0
		assets[currId].ap = 0
		assets[currId].wv = 0
	else
		if assets[currId].gold == nil then
			assets[currId].gold = 0
		end
		if assets[currId].tv == nil then
			assets[currId].tv = 0
		end
		if assets[currId].ap == nil then
			assets[currId].ap = 0
		end
		if assets[currId].wv == nil then
			assets[currId].wv = 0
		end
	end

	self.currAssets = assets[currId]

	self.frame:SetAnchor(TOPLEFT, IIFA_GUI_Header_GoldButton, TOPRIGHT, 5, 0)
	self.totGold = 0
	self.totTV = 0
	self.totAP = 0
	self.totWV = 0

	for i=1, GetNumCharacters() do
		local charName, _, _, _, _, alliance, charId, _ = GetCharacterInfo(i)
		charName = zo_strformat(SI_UNIT_NAME, charName)
		tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_" .. i, self.frame, "IIFA_CharCurrencyRow")
		table.insert(self.controls, tControl)
		if i == 1 then
			tControl:SetAnchor(TOPLEFT, self.frame, TOPLEFT, 0, 52)
			prevControl:GetNamedChild("_Title"):SetText(GetString(SI_INVENTORY_MODE_CURRENCY))
			prevControl:GetNamedChild("_TitleCharName"):SetText(GetString(SI_GROUP_LIST_PANEL_NAME_HEADER))
		else
			tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 2)
		end
		tControl:GetNamedChild("charName"):SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
		tControl:GetNamedChild("charName"):SetText(GetAllianceColor(alliance):Colorize(charName))
		tControl:GetNamedChild("charName").rawCharName = charName
		if GetCurrentCharacterId() == charId then
			self.charControl = tControl
		else
			if assets[charId] ~= nil then
				if assets[charId].gold == nil then
					assets[charId].gold = 0
				end
				self.totGold = self.totGold + assets[charId].gold

				if assets[charId].tv == nil then
					assets[charId].tv = 0
				end
				self.totTV = self.totTV + assets[charId].tv

				if assets[charId].ap == nil then
					assets[charId].ap = 0
				end
				self.totAP = self.totAP + assets[charId].ap

				if assets[charId].wv == nil then
					assets[charId].wv = 0
				end
				self.totWV = self.totWV + assets[charId].wv

				self:SetQty(tControl, "qtyGold", CURT_MONEY, assets[charId].gold, "Others")
				self:SetQty(tControl, "qtyTV", CURT_TELVAR_STONES, assets[charId].tv, "Others")
				self:SetQty(tControl, "qtyAP", CURT_ALLIANCE_POINTS, assets[charId].ap, "Others")
				self:SetQty(tControl, "qtyWV", CURT_WRIT_VOUCHERS, assets[charId].wv, "Others")
			end
		end
		prevControl = tControl
	end

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider1", self.frame, "ZO_Options_Divider")
	tControl:SetHeight(3)
	tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, -2, 0)
	tControl:SetAnchor(TOPRIGHT, prevControl, BOTTOMRIGHT, 0, 0)
	tControl:SetAlpha(1)
	self.divider1 = tControl
	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider1Flipped", self.frame, "ZO_Options_Divider")
	tControl:SetHeight(3)
	tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 0)
	tControl:SetAnchor(TOPRIGHT, prevControl, BOTTOMRIGHT, 3, 0)
	tControl:SetAlpha(1)
	tControl:SetTextureCoordsRotation(-1)

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Bank", self.frame, "IIFA_CharCurrencyRow")
	table.insert(self.controls, tControl)
	tControl:GetNamedChild("charName"):SetText(GetString(SI_CURRENCYLOCATION1))
	tControl:GetNamedChild("charName").rawCharName = GetString(SI_CURRENCYLOCATION1)
	tControl:SetAnchor(TOPLEFT, self.divider1, BOTTOMLEFT, 2, 0)
	self.bankControl = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider2", self.frame, "ZO_Options_Divider")
	tControl:SetHeight(3)
	tControl:SetAnchor(TOPLEFT, self.bankControl, BOTTOMLEFT, -2, 0)
	tControl:SetAnchor(TOPRIGHT, self.bankControl, BOTTOMRIGHT, 0, 0)
	tControl:SetAlpha(1)
	self.divider2 = tControl
	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider2Flipped", self.frame, "ZO_Options_Divider")
	tControl:SetHeight(3)
	tControl:SetAnchor(TOPLEFT, self.bankControl, BOTTOMLEFT, 0, 0)
	tControl:SetAnchor(TOPRIGHT, self.bankControl, BOTTOMRIGHT, 3, 0)
	tControl:SetAlpha(1)
	tControl:SetTextureCoordsRotation(-1)


	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Tots", self.frame, "IIFA_CharCurrencyRow")
	table.insert(self.controls, tControl)
	tControl:GetNamedChild("charName"):SetText("Totals")
	tControl:GetNamedChild("charName").rawCharName = "Totals"
	tControl:SetAnchor(TOPLEFT, self.divider2, BOTTOMLEFT, 2, 0)	-- offset has to account for offset of the divider
	self.totControl = tControl

	local ctr, tControl, ctl
	ctl = self.frame:GetNamedChild("_TitleCharName")
	charNameMaxWidth = ctl:GetStringWidth(ctl:GetText())
	for ctr, tControl in pairs(self.controls) do
		ctl = tControl:GetNamedChild("charName")
		charNameWidth = ctl:GetStringWidth(ctl.rawCharName) / GetUIGlobalScale()
		if charNameWidth > charNameMaxWidth then
			charNameMaxWidth = charNameWidth
		end
	end

	self.frame:GetNamedChild("_TitleCharName"):SetWidth(charNameMaxWidth + 6)
	for ctr, tControl in pairs(self.controls) do
		tControl:GetNamedChild("charName"):SetWidth(charNameMaxWidth + 6)
	end

	self.frame:SetHeight((GetNumCharacters() + 4) * 26)	-- numchars + 4 represents # chars + bank + total + title and col titles

	self:FillCharAndBank()

	self.isInitialized = true
end

function CharCurrencyFrame:Show(control)
	if self.isInitialized == nil then return end
	if not self.isShowing then
		self.isShowing = true
		self:FillCharAndBank()
		self.frame:SetHidden(false)
	end
end

function CharCurrencyFrame:Hide(control)
	if self.isInitialized == nil then return end
	if self.isShowing then
		self.isShowing = false
		self.frame:SetHidden(true)
	end
end

