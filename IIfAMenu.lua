--this creates a menu for the addon.
IIfA = IIfA

function IIfA.IN2_CreateSettingsWindow(savedVars, defaults)
   local LAM = LibStub("LibAddonMenu-2.0")
   local LMP = LibStub("LibMediaProvider-1.0")

   local deleteme
   local fontSize

   local panelData = {
		type = "panel",
		name = IIfA.name,
		displayName = name,
	 	author = IIfA.author,
		version = IIfA.version,
		slashCommand = "/IIfA",	--(optional) will register a keybind to open to this panel
		registerForRefresh = true,	--boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
		registerForDefaults = true	--boolean (optional) (will set all options controls back to default values)
	}

  LAM:RegisterAddonPanel("IIfA_OptionsPanel", panelData)

	local optionsData = {
		{
			type = "checkbox",
			tooltip = "Prints verbose debugging to the ChatFrame.",
			name = "Debugging",
			getFunc = function() return IIfA.settings.in2Debug end,
			setFunc = function(value) IIfA.settings.in2Debug = value end
		},

		{
			type = "submenu",
			name = "Manage Collected Data",
			tooltip = "Manage collected Characters and Guild Banks. Delete data you no longer need (old guilds or deleted characters).",	--(optional)
			controls = {

				{
					type = "dropdown",
					name = "Character To Delete",
					choices = IIfA.IN2_CharacterInventories(),
					getFunc = function() return end,
					setFunc = function(choice) deleteme = nil; deleteme = choice end
				}, --dropdown end

				{  -- button begin
					type = "button",
					name = "Delete Character",
					tooltip = "Delete Inventory Insight data for the character selected above.",
					warning = "All data for the selected character above will be deleted!",
					func = function() IIfA.DeleteCharacterData(deleteme) end,

				}, -- button end

				{ -- dropdown begin
					 type = "dropdown",
					 name = 'Guild Bank To Delete',
					 tooltip = 'Delete Inventory Insight data for guild',
					 choices = IIfA.IN2_GuildBanks(),
					 getFunc = function() return end,
					 setFunc = function(choice) deleteme = nil; deleteme = choice end

				}, -- dropdown end

				{	-- button begin
					type = "button",
					name = "Delete Guild Bank",
					tooltip = "Delete Inventory Insight data for the guild selected above.",
					warning = "All data for the selected guild bank above will be deleted!",
					func = function() IIfA.DeleteGuildData(deleteme) end,
				}, -- button end


			}, -- Collected Guild Bank Data controls end

		}, -- Collected Guild Bank Data submenu end


		--IIfA:IsRasLoaded(),

		{
			type = "submenu",
			name = "Data Collection",
			tooltip = "Manage data collection options for inventories and guild banks.",
			controls = {

				{
					type = "checkbox",
					name = "Data Collection",
					tooltip = "Enables/Disables data collection for this character.",
					warning = "Inventory information will not be updated if this option is turned off!",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 2 occurances
					getFunc = function () return IIfA.settings.in2ToggleDataCollection end,
					setFunc = function(value)
						IIfA.settings.in2ToggleDataCollection = value
					end,
				},

				{
					type = "checkbox",
					name = "Guild Bank Data Collection",
					tooltip = "Enables/Disables data collection for guild banks on this account.",
					warning = "Guild bank information will not be updated if this option is turned off!",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 2 occurances
					getFunc = function() return IIfA.settings.in2ToggleGuildBankDataCollection end,
					setFunc = function(value)
						IIfA.settings.in2ToggleGuildBankDataCollection = value
						end,
				}, -- checkbox end

				{
					type = "checkbox",
					name = "Old Guild Bank Data Alert",
					tooltip = "Enables/Disables an alert that will notify you once, when you first log in, if one or more guild banks contain data that is 5 days or older.",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 2 occurances
					getFunc = function() return IIfA.settings.in2AgedGuildBankDataWarning end,
					setFunc = function(value)
						IIfA.settings.in2AgedGuildBankDataWarning = value
						end,
				}, -- checkbox end

			 }, -- controls end


		}, -- _in2OptionsDataCollectionSubWindow end

		{
			type = "submenu",
			name = "Tooltips",
			tooltip = "Managae tooltip options for both default and custom IN2 tooltips.",
			controls = {

				{
					type = "checkbox",
					name = "Use Default Tooltips",
					tooltip = "Enables/Disables inventory insight data added to the default tooltips. (Turning this feature on will disable the IIfA Tooltips).",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 3 occurances
					getFunc = function() return IIfA.settings.in2ToggleDefaultTooltips end,
					setFunc = function(value)
						IIfA.settings.in2ToggleDefaultTooltips = value
						IIfA.settings.in2ToggleIN2Tooltips = not value
					end,


				}, -- checkbox end

				{
					type = "checkbox",
					name = "Use IIfA Tooltips",
					tooltip = "Enables/Disables inventory insight data added to the IIfA tooltips. (Turning this feature on will disable adding data to the default Tooltips",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 3 occurances
					getFunc = function() return IIfA.settings.in2ToggleIN2Tooltips end,
					setFunc = function(value)
						IIfA.settings.in2ToggleIN2Tooltips = value
						IIfA.settings.in2ToggleDefaultTooltips = not value
					end,

				}, -- checkbox end

				{
					type = "checkbox",
					name = 'Hide Redundant Item Information',
					tooltip = 'Option to enable/disable showing information on ItemTooltips (inventory and bank) when already viewing that bag. (i.e., If you mouse over an item in your inventory you can already see how many you have.)',
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 2 occurances
					getFunc = function() return IIfA.settings.in2HideRedundantInfo end,
					setFunc = function(value) IIfA.settings.in2HideRedundantInfo = value end,
				}, -- checkbox end

--[[				{
					type = "checkbox",
					name = 'Show Worn Indicators',
					tooltip = 'Option to enable/disable displaying \'[WORN]\' in front of location if the item in the tooltip is a worn piece of equipment on that character.',
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 2 occurances
					getFunc = function() return IIfA.settings.in2TooltipsShowWornIndicator end,
					setFunc = function(value) IIfA.settings.in2TooltipsShowWornIndicator = value end,
				}, -- checkbox end
--]]
				 {
					type = "colorpicker",
					name = 'Tooltip Inventory Information Text Color',
					tooltip = 'Sets the color of the text for the inventory information that gets added to Tooltips.',
					getFunc = function() return IIfA.GetColour() end,
					setFunc = function(...)
						local colourHandler = IIfA.SetColour(...);
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings.
						IIfA.settings.in2TextColors = colourHandler:ToHex();
					end
				},

				{
					type = "dropdown",
					name = "Tooltips Font",
					tooltip = "The font used for location information added to both default and custom IN2 tooltips.",
					choices = LMP:List('font'),
					getFunc = function() return IIfA.GetTooltipFont() end,
					setFunc = function( choice )
						IIfA.IN2_StatusAlert("[IIfA]:TooltipsFontChanged["..choice.."]")
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings.
						IIfA.settings.in2TooltipsFont = choice
					end

				},

				{
					type = "slider",
					name = "Tooltip Font Size",
					tooltip = "The font size used for location information added to both default and custom IN2 tooltips.",
					min = 5,
					max = 40,
					step = 1,
					getFunc = function() return IIfA.settings.in2TooltipsFontSize end,
					setFunc = function(value)
						IIfA.settings.in2TooltipsFontSize = value
					end,
				},

-- 2015-3-29 - AssemblerManiac - Removed +/- buttons, replaced with slider above - no more guessing at what size you have it set to
--[[
				{  -- button begin
					type = "button",
					width = "half",
					name = "+",
					tooltip = "Increase Tooltip Font Size",
					func = function()
					--	fontSize = IIfA.GetToolTipFontSize()
						fontSize = IIfA.settings.in2TooltipsFontSize
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings.
						IIfA.settings.in2TooltipsFontSize = fontSize + 1
					end,

				}, -- button end

				{  -- button begin
					type = "button",
					width = "half",
					name = "-",
					tooltip = "Decrease Tooltip Font Size",
					func = function()
					--	fontSize = IIfA.GetToolTipFontSize()
						fontSize = IIfA.settings.in2TooltipsFontSize
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings.
						IIfA.settings.in2TooltipsFontSize = fontSize - 1
					end,

				}, -- button end
--]]
				{
				type = "checkbox",
				name = 'Minimal Padding Default Tooltips',
				tooltip = 'Option to enable/disable minimal padding inside the default ItemTooltips and PopupTooltips in the UI.',
				warning = "This affects the default tooltips even when not being used by Inventory Insight!",
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 4 occurances
				getFunc = function() return IIfA.settings.in2DefaultTooltipsMinimalPadding end,
				setFunc = function()
					local ItemTooltip = ItemTooltip
					local PopupTooltip = PopupTooltip
					if( IIfA.settings.in2DefaultTooltipsMinimalPadding ) then
						IIfA.IN2_StatusAlert("[IIfA]:DefaultTooltipsMinimalPadding[Off]")
						IIfA.settings.in2DefaultTooltipsMinimalPadding = false;
						IIfA.IN2_AdjustTooltipPadding(ItemTooltip, false)
						IIfA.IN2_AdjustTooltipPadding(PopupTooltip, false)
					else
						IIfA.IN2_StatusAlert("[IIfA]:DefaultTooltipsMinimalPadding[On]")
						IIfA.settings.in2DefaultTooltipsMinimalPadding = true;
						IIfA.IN2_AdjustTooltipPadding(ItemTooltip, true)
						IIfA.IN2_AdjustTooltipPadding(PopupTooltip, true)
					end
					return
				end,

			}, -- checkbox end

				{
					type = "checkbox",
					name = 'Minimal Padding IN2 Tooltips',
					tooltip = 'Option to enable/disable minimal padding inside the Inventory Insight ItemTooltips and PopupTooltips in the UI.',
					-- 3-29-15 - AssemblerManiac - changed .data. to .settings. next 4 occurances
					getFunc = function() return IIfA.settings.in2IN2TooltipsMinimalPadding end,
					setFunc = function()
						local ItemTooltip = IN2_ITEM_TOOLTIP
						local PopupTooltip = IN2_POPUP_TOOLTIP
						if( IIfA.settings.in2IN2TooltipsMinimalPadding ) then
							IIfA.IN2_StatusAlert("[IIfA]:IN2TooltipsMinimalPadding[Off]")
							IIfA.settings.in2IN2TooltipsMinimalPadding = false;
							IIfA.IN2_AdjustTooltipPadding(ItemTooltip, false)
							IIfA.IN2_AdjustTooltipPadding(PopupTooltip, false)
						else
							IIfA.IN2_StatusAlert("[IIfA]:IN2TooltipsMinimalPadding[On]")
							IIfA.settings.in2IN2TooltipsMinimalPadding = true;
							IIfA.IN2_AdjustTooltipPadding(ItemTooltip, true)
							IIfA.IN2_AdjustTooltipPadding(PopupTooltip, true)
						end
						return
					end

				}, -- checkbox minimal padding end


			}, -- controls end


		}, -- tooltipOptionsSubWindow end

		-- {
			-- type = "checkbox",
			-- tooltip = "Adds the IIfA Inventory Frame to your default UI. (Visibly from inventory/bank/guild bank/merchant interfaces.)",
			-- name = "Show Inventory Frame",
			-- getFunc = function() return IIfA.settings.in2ShowInventoryFrame end,
			-- setFunc = function(value)
					-- IIfA.IN2_StatusAlert("[IIfA]:ShowInventoryFrame[" .. tostring(value) .. "]")
					-- IIfA.settings.in2ShowInventoryFrame = value;
					-- IIfA.toggleSceneVisibility(value)
			-- end,
		-- },

		{
			type = "checkbox",
			tooltip = "Undocks the IIfA Inventory Frame from your default UI Character Frame (left side). Unlocked, the Inventory Frame can be positioned around the screen for the duration of the session.",
			name = "Undock Inventory Frame",
			getFunc = function() return IIfA.settings.in2ReleaseInventoryFrame end;
			setFunc = function(value) IIfA.settings.in2ReleaseInventoryFrame = value end;
		},

		 {
			type = "dropdown",
			name =  "Default Inventory Frame View",
			tooltip =  "The default view (in the dropdown) set when the inventory frame loads.",
			choices = { "All", "All Banks", "All Guild Banks", "All Characters", "Bank and Characters", "Bank Only" },
			default = IIfA.GetDefaultFilter(),
			getFunc = function() return IIfA.settings.in2DefaultInventoryFrameView end,
			setFunc = function( value )
				IIfA.IN2_StatusAlert("[IIfA]:DefaultInventoryFrameView["..value.."]")
				IIfA.settings.in2DefaultInventoryFrameView = value;
				-- 2015-3-9 Assembler Maniac - next line changed to stop crash
				ZO_ComboBox_ObjectFromContainer(IN2_INVENTORY_DROPDOWN_CONTROL):SetSelectedItem(value)
				IIfA.IN2_SetVisibleInventory(value)
				return
			end
			-- warning = "Will need to reload the UI.",	--(optional)
		},

		{
			type = "checkbox",
			name = "Inventory scene",
			tooltip = "Makes the Inventory Frame visible while viewing your inventory.",
			getFunc = function() return IIfA.GetSceneVisible("inventory") end,
			setFunc = function(value) IIfA.SetSceneVisible("inventory", value) end,

			},

		{
			type = "checkbox",
			tooltip = "Makes the Inventory Frame visible while viewing your bank .",
			name = "Bank scene",
			getFunc = function() return IIfA.GetSceneVisible("bank") end,
			setFunc = function(value) IIfA.SetSceneVisible("bank", value) end,
		},

		{
			type = "checkbox",
			name = "Guild Bank scene",
			tooltip = "Makes the Inventory Frame visible while viewing your guild vault.",
			getFunc = function() return IIfA.GetSceneVisible("guildBank") end,
			setFunc = function(value) IIfA.SetSceneVisible("guildBank", value) end,
		},

		{
			type = "checkbox",
			name = "Guild Store scene",
			tooltip = "Makes the Inventory Frame visible while accessing the guild store.",
			getFunc = function() return IIfA.GetSceneVisible("tradinghouse") end,
			setFunc = function(value) IIfA.SetSceneVisible("tradinghouse", value) end,
		},

		 {
			type = "checkbox",
			name = "Crafting scene",
			tooltip = "Makes the Inventory Frame visible while Crafting.",
			getFunc = function() return IIfA.GetSceneVisible("smithing") end,
			setFunc = function(value) IIfA.SetSceneVisible("smithing", value) end,
		},

		 {
			type = "checkbox",
			name = "Vendor scene",
			tooltip = "Makes the Inventory Frame visible while buying/selling.",
			getFunc = function() return IIfA.GetSceneVisible("store") end,
			setFunc = function(value) IIfA.SetSceneVisible("store", value) end,
		},


		 {
			type = "checkbox",
			name = "Trading scene",
			tooltip = "Makes the Inventory Frame visible while trading.",
			getFunc = function() return IIfA.GetSceneVisible("trade") end,
			setFunc = function(value) IIfA.SetSceneVisible("trade", value) end,
		},

	-- options data end
	}
   LAM:RegisterOptionControls("IIfA_OptionsPanel", optionsData)

   end
