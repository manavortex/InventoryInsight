local CharBagFrame = ZO_Object:Subclass()
if IIfA == nil then IIfA = {} end
IIfA.CharBagFrame = CharBagFrame
CharBagFrame.EMPTY_STRING = ""

--[[ not currently used
local function HexToN(sHexVal)
	local Nibble1=0
	local Nibble2=0
	Nibble1, Nibble2=string.byte(sHexVal,1,2)
	if Nibble1>=65 then
		Nibble1=Nibble1-55
	else
		Nibble1=Nibble1-48
	end
	if Nibble2>=65 then
		Nibble2=Nibble2-55
	else
		Nibble2=Nibble2-48
	end
	local Byte=Nibble1*16+Nibble2
	return Byte/255
end
--]]

local function nToHex(Byte)
--	local Byte=nVal * 255
	local Nibble1=math.floor(Byte/16)
	local Nibble2=Byte-(Nibble1*16)
	local Part1=string.char(Nibble1+48)
	local Part2=string.char(Nibble2+48)
	if Nibble1>9 then
		Part1=string.char(Nibble1+55)
	end
	if Nibble2>9 then
		Part2=string.char(Nibble2+55)
	end
	return string.format("%s%s", Part1, Part2)
end

function CharBagFrame:rgb2hex(ay)
	-- local rtn
	return string.format("%s%s%s", nToHex(ay.r * 255), nToHex(ay.g * 255), nToHex(ay.b * 255))
	-- return rtn
end

local function ColorStart(colorHTML)
	return string.format("%s%s", "|c",string.sub(colorHTML,1,6))
end

function CharBagFrame:ComputeColorAndText(spaceCurr, spaceMax)
	local usedBagPercent = tonumber(spaceCurr) * 100 / tonumber(spaceMax)
	local cs = self.EMPTY_STRING
	if spaceCurr == spaceMax then
		cs = ColorStart(self.ColorFull)
	else
		if usedBagPercent >= self.parent.BagSpaceAlert.threshold then
			cs = ColorStart(self.ColorAlert)
		else
			if usedBagPercent >= self.parent.BagSpaceWarn.threshold then
				cs = ColorStart(self.ColorWarn)
			end
		end
	end
	return cs .. spaceCurr
end


function CharBagFrame:SetQty(control, field, qty)
	local ctl = control:GetNamedChild(field)
	ctl:SetText(qty)
end

function CharBagFrame:UpdateAssets()
	if self.currAssets ~= nil then
		self.currAssets.spaceUsed = GetNumBagUsedSlots(BAG_BACKPACK)
		self.currAssets.spaceMax = GetBagSize(BAG_BACKPACK)
	end
end

function CharBagFrame:FillCharAndBank()
	self:UpdateAssets()

	local spaceUsed = self.currAssets.spaceUsed
	local spaceMax = self.currAssets.spaceMax
	local bankMax = GetBagSize(BAG_BANK)
	if IsESOPlusSubscriber() then
		bankMax = bankMax + GetBagSize(BAG_SUBSCRIBER_BANK)
	end
	local bankUsed = GetNumBagUsedSlots(BAG_BANK)
	bankUsed = bankUsed + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)

	self:SetQty(self.charControl, "spaceUsed", self:ComputeColorAndText(spaceUsed, spaceMax))
	self:SetQty(self.charControl, "spaceMax", spaceMax)

	self:SetQty(self.bankControl, "spaceUsed", self:ComputeColorAndText(bankUsed, bankMax))
	self:SetQty(self.bankControl, "spaceMax", bankMax)

	spaceUsed = spaceUsed + bankUsed + self.totSpaceUsed
	spaceMax = spaceMax + bankMax + self.totSpaceMax

	-- housing chests
	local bInHouse, ctr, tempUsed, bFoundData, tControl
	local cName
	local iChestCount = 0
	local bInOwnedHouse = IsOwnerOfCurrentHouse()

	for ctr = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
		tControl = self.houseChestControls[ctr]
		if IsCollectibleUnlocked(GetCollectibleForHouseBankBag(ctr)) then
			if bInOwnedHouse then
				tempUsed = GetNumBagUsedSlots(ctr)
				self.parent.houseChestSpace[ctr] = tempUsed
				bFoundData = true
			else
				if self.parent.houseChestSpace[ctr] ~= nil then
					tempUsed = self.parent.houseChestSpace[ctr]
					bFoundData = true
				else
					tempUsed = nil
				end
			end
			iChestCount = iChestCount + 1
			if tempUsed ~= nil then
				tControl:SetHeight(26)
				self:SetQty(tControl, "spaceUsed", self:ComputeColorAndText(tempUsed, GetBagSize(ctr)))
				self:SetQty(tControl, "spaceMax", GetBagSize(ctr))
				cName = GetCollectibleNickname(GetCollectibleForHouseBankBag(ctr))
				if cName == self.EMPTY_STRING then
					cName = GetCollectibleName(GetCollectibleForHouseBankBag(ctr))
				end
				tControl:GetNamedChild("charName"):SetText(zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, cName))
				spaceUsed = spaceUsed + tempUsed
				spaceMax = spaceMax + GetBagSize(ctr)
			end
		else
			tControl:SetHeight(0)
			tControl:GetNamedChild("charName"):SetText("")
			self.parent.houseChestSpace[ctr] = nil
		end
	end

	local iDivCount = 2
	if iChestCount > 0 then
		self.divider3:SetHeight(3)
		if not bFoundData then
			local alertText = ZO_ERROR_COLOR:Colorize("Enter House once")
			tControl = self.houseChestControls[BAG_HOUSE_BANK_ONE]
			tControl:SetHeight(26)
			tControl:GetNamedChild("charName"):SetText(alertText)
		end
		iDivCount = iDivCount + 1
	end

	local iFrameHeight = ((GetNumCharacters() + 4 + iChestCount) * 26) + (iDivCount * 3)	-- numchars + numChests + 4 (title line + bank + total + dividers)

	self.frame:SetHeight(iFrameHeight)

	self:SetQty(self.totControl, "spaceUsed", spaceUsed)
	self:SetQty(self.totControl, "spaceMax", spaceMax)

end

-- add iteration for house chests
-- if GetBagSize == 0, you've run out of chests to iterate (break out of loop)
-- /script for i=BAG_HOUSE_BANK_ONE,BAG_MAX_VALUE do d(i .. GetCollectibleName(GetCollectibleForHouseBankBag(i))) end
-- /script for i=BAG_HOUSE_BANK_ONE,BAG_MAX_VALUE do d(i .. " " .. IsCollectibleUnlocked(GetCollectibleForHouseBankBag(i))) end

function CharBagFrame:RepaintSpaceUsed()
	-- loop through characters
	local assets = self.parent.assets
	for i=1, GetNumCharacters() do
		local _, _, _, _, _, _, charId, _ = GetCharacterInfo(i)
		local tControl = GetControl("IIFA_GUI_Bag_Grid_Row_" .. i)
		if charId ~= currId then
			if assets[charId] ~= nil then
				if assets[charId].spaceUsed ~= nil then
					self:SetQty(tControl, "spaceUsed", self:ComputeColorAndText(assets[charId].spaceUsed, assets[charId].spaceMax))
					self:SetQty(tControl, "spaceMax", assets[charId].spaceMax)
				end
			end
		end
	end
end


function CharBagFrame:Initialize(objectForAssets)
	self.frame = IIFA_CharBagFrame
	local tControl
	local prevControl = self.frame
	local currId = GetCurrentCharacterId()

	if objectForAssets.assets == nil then
		objectForAssets.assets = {}
	end
	local assets = objectForAssets.assets
	self.parent = objectForAssets

	if assets[currId] == nil then
		assets[currId] = {}
		assets[currId].spaceUsed = 0
		assets[currId].spaceMax = 0
	else
		if assets[currId].spaceUsed == nil then
			assets[currId].spaceUsed = 0
		end
		if assets[currId].spaceMax == nil then
			assets[currId].spaceMax = 0
		end
	end
	if objectForAssets.BagSpaceWarn == nil then
		objectForAssets.BagSpaceWarn = { threshold = 85, r = 230 / 255, g = 130 / 255, b = 0 }
		objectForAssets.BagSpaceAlert = { threshold = 95, r = 1, g = 1, b = 0 }
		objectForAssets.BagSpaceFull = { r = 1, g = 0, b = 0 }
	end

	self.ColorWarn = self:rgb2hex(objectForAssets.BagSpaceWarn)
	self.ColorAlert = self:rgb2hex(objectForAssets.BagSpaceAlert)
	self.ColorFull = self:rgb2hex(objectForAssets.BagSpaceFull)

	self.currAssets = objectForAssets.assets[currId]

	self.frame:SetAnchor(TOPLEFT, IIFA_GUI_Header_BagButton, TOPRIGHT, 5, 0)
	self.totSpaceUsed = 0
	self.totSpaceMax = 0

	for i=1, GetNumCharacters() do
		local charName, _, _, _, _, alliance, charId, _ = GetCharacterInfo(i)
		charName = charName:sub(1, charName:find("%^") - 1)
		tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Grid_Row_" .. i, self.frame, "IIFA_CharBagRow")
		if i == 1 then
			tControl:SetAnchor(TOPLEFT, prevControl:GetNamedChild("_Title"), BOTTOMLEFT, 0, 30)
			prevControl:GetNamedChild("_Title"):SetText("Bag Space")
			prevControl:GetNamedChild("_TitleCharName"):SetText(GetString(SI_GROUP_LIST_PANEL_NAME_HEADER))
		else
			tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 2)
		end
		tControl:GetNamedChild("charName"):SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
		tControl:GetNamedChild("charName"):SetText(GetAllianceColor(alliance):Colorize(charName))
		if charId == currId then
			self.charControl = tControl
		else
			if assets[charId] ~= nil then
				if assets[charId].houseChestSpace ~= nil then
					assets[charId].houseChestSpace = nil
				end
				if assets[charId].spaceUsed ~= nil then
					self.totSpaceUsed = self.totSpaceUsed + assets[charId].spaceUsed
					self.totSpaceMax = self.totSpaceMax + assets[charId].spaceMax

					self:SetQty(tControl, "spaceUsed", self:ComputeColorAndText(assets[charId].spaceUsed, assets[charId].spaceMax))
					self:SetQty(tControl, "spaceMax", assets[charId].spaceMax)
				end
			end
		end
		prevControl = tControl
	end

	tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_Divider1", self.frame, "ZO_Options_Divider")
	tControl:SetDimensions(288, 3)
	tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 0)
	tControl:SetAlpha(1)
	self.divider1 = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_Bank", self.frame, "IIFA_CharBagRow")
	tControl:GetNamedChild("charName"):SetText(GetString(SI_CURRENCYLOCATION1))
	tControl:SetAnchor(TOPLEFT, self.divider1, BOTTOMLEFT, 0, 0)
	self.bankControl = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_Divider2", self.frame, "ZO_Options_Divider")
	tControl:SetDimensions(288, 3)
	tControl:SetAnchor(TOPLEFT, self.bankControl, BOTTOMLEFT, 0, 0)
	tControl:SetAlpha(1)
	self.divider2 = tControl

	self.houseChestControls = {}
	self.parent.houseChestSpace = self.parent.houseChestSpace or {}
	local ctr
	prevControl = self.divider2
	for ctr = BAG_HOUSE_BANK_ONE,BAG_HOUSE_BANK_TEN do
		tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_House_Bank" .. ctr, self.frame, "IIFA_CharBagRow")
		tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 0)
		tControl:SetHeight(0)
		self.houseChestControls[ctr] = tControl
		prevControl = tControl
	end

	tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_Divider3", self.frame, "ZO_Options_Divider")
	tControl:SetDimensions(288, 0)
	tControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 0)
	tControl:SetAlpha(1)
	self.divider3 = tControl

	tControl = CreateControlFromVirtual("IIFA_GUI_Bag_Row_Tots", self.frame, "IIFA_CharBagRow")
	tControl:GetNamedChild("charName"):SetText("Totals")
	tControl:SetAnchor(TOPLEFT, self.divider3, BOTTOMLEFT, 0, 0)
	self.totControl = tControl

	self:FillCharAndBank()

	self.isInitialized = true
end

function CharBagFrame:Show(control)
	if self.isInitialized == nil then return end
	if not self.isShowing then
		self.isShowing = true
		self:FillCharAndBank()
		self.frame:SetHidden(false)
	end
end

function CharBagFrame:Hide(control)
	if self.isInitialized == nil then return end
	if self.isShowing then
		self.isShowing = false
		self.frame:SetHidden(true)
	end
end

