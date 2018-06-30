local CharCurrencyFrame = ZO_Object:Subclass()
if IIfA == nil then IIfA = {} end
IIfA.CharCurrencyFrame = CharCurrencyFrame

local g_currenciesData = ZO_CURRENCIES_DATA
local function GetCurrencyColor(currencyType)
	return g_currenciesData[currencyType].color
end

function CharCurrencyFrame:SetQty(control, field, fieldType, qty)
	local ctl = control:GetNamedChild(field)

	if qty == nil then
		qty = 0
	end

	ctl:SetText(GetCurrencyColor(fieldType):Colorize(ZO_CurrencyControl_FormatCurrency(qty)))
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

	self:SetQty(self.charControl, "qtyGold", CURT_MONEY, gold)
	self:SetQty(self.charControl, "qtyTV", CURT_TELVAR_STONES, tv)
	self:SetQty(self.charControl, "qtyAP", CURT_ALLIANCE_POINTS, ap)
	self:SetQty(self.charControl, "qtyWV", CURT_WRIT_VOUCHERS, wv)

	local bankedMoney = GetBankedCurrencyAmount(CURT_MONEY)
	local bankedTelVarStones = GetBankedCurrencyAmount(CURT_TELVAR_STONES)
	local bankedAlliancePoints = GetBankedCurrencyAmount(CURT_ALLIANCE_POINTS)
	local bankedWritVouchers = GetBankedCurrencyAmount(CURT_WRIT_VOUCHERS)

	self:SetQty(self.bankControl, "qtyGold", CURT_MONEY, bankedMoney)
	self:SetQty(self.bankControl, "qtyTV", CURT_TELVAR_STONES, bankedTelVarStones)
	self:SetQty(self.bankControl, "qtyAP", CURT_ALLIANCE_POINTS, bankedAlliancePoints)
	self:SetQty(self.bankControl, "qtyWV", CURT_WRIT_VOUCHERS, bankedWritVouchers)

	gold = gold + bankedMoney + self.totGold
	tv = tv + bankedTelVarStones + self.totTV
	ap = ap + bankedAlliancePoints + self.totAP
	wv = wv + bankedWritVouchers + self.totWV

	self:SetQty(self.totControl, "qtyGold", CURT_MONEY, gold)
	self:SetQty(self.totControl, "qtyTV", CURT_TELVAR_STONES, tv)
	self:SetQty(self.totControl, "qtyAP", CURT_ALLIANCE_POINTS, ap)
	self:SetQty(self.totControl, "qtyWV", CURT_WRIT_VOUCHERS, wv)

-- field width testing
--	self:SetQty(self.totControl, "qtyGold", CURT_MONEY, 99999999)
--	self:SetQty(self.totControl, "qtyTV", CURT_TELVAR_STONES, 99999999)
--	self:SetQty(self.totControl, "qtyAP", CURT_ALLIANCE_POINTS, 99999999)
end


function CharCurrencyFrame:Initialize(objectForAssets)
	self.frame = IIFA_CharCurrencyFrame
	local tControl
	local prevControl = self.frame
	local currId = GetCurrentCharacterId()

	local iconSize = 18
	prevControl:GetNamedChild("CURT_MONEY"):SetTexture(GetCurrencyKeyboardIcon(CURT_MONEY))
	prevControl:GetNamedChild("CURT_MONEY"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("CURT_ALLIANCE_POINTS"):SetTexture(GetCurrencyKeyboardIcon(CURT_ALLIANCE_POINTS))
	prevControl:GetNamedChild("CURT_ALLIANCE_POINTS"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("CURT_TELVAR_STONES"):SetTexture(GetCurrencyKeyboardIcon(CURT_TELVAR_STONES))
	prevControl:GetNamedChild("CURT_TELVAR_STONES"):SetDimensions(iconSize, iconSize)
	prevControl:GetNamedChild("CURT_WRIT_VOUCHERS"):SetTexture(GetCurrencyKeyboardIcon(CURT_WRIT_VOUCHERS))
	prevControl:GetNamedChild("CURT_WRIT_VOUCHERS"):SetDimensions(iconSize, iconSize)

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
		if i == 1 then
			tControl:SetAnchor(TOPLEFT, prevControl:GetNamedChild("_Title"), BOTTOMLEFT, 0, 26)
			prevControl:GetNamedChild("_Title"):SetText(GetString(SI_INVENTORY_MODE_CURRENCY))
			prevControl:GetNamedChild("_TitleCharName"):SetText(GetString(SI_GROUP_LIST_PANEL_NAME_HEADER))
		else
			tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 2)
		end
		tControl:GetNamedChild("charName"):SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
		tControl:GetNamedChild("charName"):SetText(GetAllianceColor(alliance):Colorize(charName))
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

				self:SetQty(tControl, "qtyGold", CURT_MONEY, assets[charId].gold)
				self:SetQty(tControl, "qtyTV", CURT_TELVAR_STONES, assets[charId].tv)
				self:SetQty(tControl, "qtyAP", CURT_ALLIANCE_POINTS, assets[charId].ap)
				self:SetQty(tControl, "qtyWV", CURT_WRIT_VOUCHERS, assets[charId].wv)
			end
		end
		prevControl = tControl
	end

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider1", self.frame, "ZO_Options_Divider")
	tControl:SetDimensions(490, 3)
	tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 0)
	tControl:SetAlpha(1)
	self.divider1 = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Bank", self.frame, "IIFA_CharCurrencyRow")
	tControl:GetNamedChild("charName"):SetText(GetString(SI_CURRENCYLOCATION1))
	tControl:SetAnchor(TOPLEFT, self.divider1, BOTTOMLEFT, 0, 0)
	self.bankControl = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Divider2", self.frame, "ZO_Options_Divider")
	tControl:SetDimensions(490, 3)
	tControl:SetAnchor(TOPLEFT, self.bankControl, BOTTOMLEFT, 0, 0)
	tControl:SetAlpha(1)
	self.divider2 = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_AssetsGrid_Row_Tots", self.frame, "IIFA_CharCurrencyRow")
	tControl:GetNamedChild("charName"):SetText("Totals")
	tControl:SetAnchor(TOPLEFT, self.divider2, BOTTOMLEFT, 0, 0)
	self.totControl = tControl


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

