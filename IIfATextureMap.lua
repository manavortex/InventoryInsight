-- ruthlessly stolen from advanced filters

local IIfA = IIfA


IIfA.textureMap = {
	
	["ALL"] = {
		upTexture = "/esoui/art/inventory/inventory_tabicon_all_up.dds",
		downTexture = "/esoui/art/inventory/inventory_tabicon_all_down.dds",
		flash = "/esoui/art/inventory/inventory_tabicon_all_over.dds"
	},

	-- weapons
	[EQUIP_TYPE_ONE_HAND] = { 
		upTexture = "/esoui/art/progression/icon_dualwield.dds",
		downTexture = "/esoui/art/progression/icon_dualwield.dds",
		flash = "/esoui/art/progression/icon_dualwield.dds",
	},
	["DESTRUCTION_STAFF"] = {
		upTexture = "/esoui/art/progression/icon_firestaff.dds",
		downTexture = "/esoui/art/progression/icon_firestaff.dds",
		flash = "/esoui/art/progression/icon_firestaff.dds",
	},
	[WEAPONTYPE_HEALING_STAFF] = {
		upTexture = "/esoui/art/progression/icon_dualwield.dds",
		downTexture = "/esoui/art/progression/icon_dualwield.dds",
		flash = "/esoui/art/progression/icon_dualwield.dds",
	},
	[WEAPONTYPE_BOW] = {
		upTexture = "/esoui/art/progression/icon_bows.dds",
		downTexture = "/esoui/art/progression/icon_bows.dds",
		flash = "/esoui/art/progression/icon_bows.dds",
	},
	[EQUIP_TYPE_TWO_HAND] = {
		upTexture = "/esoui/art/progression/icon_2handed.dds",
		downTexture = "/esoui/art/progression/icon_2handed.dds",
		flash = "/esoui/art/progression/icon_2handed.dds",
	},
	
	[ARMORTYPE_LIGHT] = { 
		upTexture = "/esoui/art/charactercreate/charactercreate_bodyicon_up.dds",
		downTexture = "/esoui/art/charactercreate/charactercreate_bodyicon_down.dds",
		flash = "/esoui/art/charactercreate/charactercreate_bodyicon_over.dds",
	},	
	[ARMORTYPE_MEDIUM] = 	{ 
		upTexture = "/esoui/art/campaign/overview_indexicon_scoring_up.dds",	
		downTexture = "/esoui/art/campaign/overview_indexicon_scoring_down.dds",
		flash = "/esoui/art/campaign/overview_indexicon_scoring_over.dds",
	},
	[ARMORTYPE_HEAVY] = 	{ 
		upTexture = "/esoui/art/inventory/inventory_tabicon_armor_up.dds",	
		downTexture = "/esoui/art/inventory/inventory_tabicon_armor_down.dds",
		flash = "/esoui/art/inventory/inventory_tabicon_armor_over.dds",
	},
	[WEAPONTYPE_SHIELD] = { 
		upTexture = "/esoui/art/guild/guildhistory_indexicon_guild_up.dds",	
		downTexture = "/esoui/art/guild/guildhistory_indexicon_guild_down.dds",
		flash = "/esoui/art/guild/guildhistory_indexicon_guild_over.dds",
	},
	["EQUIP_TYPE_JEWELLERY"] = { 
		upTexture = "/esoui/art/charactercreate/charactercreate_accessory_up.dds",	
		downTexture = "/esoui/art/charactercreate/charactercreate_accessory_down.dds",
		flash = "/esoui/art/charactercreate/charactercreate_accessory_over.dds",
	},
	
	
	--consumables
	["REPAIR"] = {
		upTexture = "IIfA/assets/consumables/repair/repair_up.dds",
		downTexture = "IIfA/assets/consumables/repair/repair_down.dds",
		flash = "IIfA/assets/consumables/repair/repair_over.dds",
	},
	["CONTAINER"] = {
		upTexture = "IIfA/assets/consumables/containers/container_up.dds",
		downTexture = "IIfA/assets/consumables/containers/container_down.dds",
		flash = "IIfA/assets/consumables/containers/container_over.dds",
	},
	["FOOD"] = {
		upTexture = "IIfA/assets/consumables/food/food_up.dds",
		downTexture = "IIfA/assets/consumables/food/food_down.dds",
		flash = "IIfA/assets/consumables/food/food_over.dds",
	},
	["DRINK"] = {
		upTexture = "IIfA/assets/consumables/drinks/drink_up.dds",
		downTexture = "IIfA/assets/consumables/drinks/drink_down.dds",
		flash = "IIfA/assets/consumables/drinks/drink_over.dds",
	},
	["POISON"] = {
		upTexture = "IIfA/assets/consumables/poison/poison_up.dds",
		downTexture = "IIfA/assets/consumables/poison/poison_down.dds",
		flash = "IIfA/assets/consumables/poison/poison_over.dds",
	},
	["POTION"] = {
		upTexture = "IIfA/assets/consumables/potion/potion_up.dds",
		downTexture = "IIfA/assets/consumables/potion/potion_down.dds",
		flash = "IIfA/assets/consumables/potion/potion_over.dds",
	},
	["RECIPE"] = {
		upTexture = "IIfA/assets/consumables/recipes/recipe_up.dds",
		downTexture = "IIfA/assets/consumables/recipes/recipe_down.dds",
		flash = "IIfA/assets/consumables/recipes/recipe_over.dds",
	},
	["MOTIF"] = {
		upTexture = "IIfA/assets/consumables/motifs/motif_up.dds",
		downTexture = "IIfA/assets/consumables/motifs/motif_down.dds",
		flash = "IIfA/assets/consumables/motifs/motif_over.dds",
	},

	--materials
	["ALCHEMY"] = {
		upTexture = "IIfA/assets/materials/alchemy/alchemy_up.dds",
		downTexture = "IIfA/assets/materials/alchemy/alchemy_down.dds",
		flash = "IIfA/assets/materials/alchemy/alchemy_over.dds",
	},
	["ATRAIT"] = {
		upTexture = "IIfA/assets/materials/atrait/atrait_up.dds",
		downTexture = "IIfA/assets/materials/atrait/atrait_down.dds",
		flash = "IIfA/assets/materials/atrait/atrait_over.dds",
	},
	["BLACKSMITHING"] = {
		upTexture = "IIfA/assets/materials/blacksmithing/blacksmithing_up.dds",
		downTexture = "IIfA/assets/materials/blacksmithing/blacksmithing_down.dds",
		flash = "IIfA/assets/materials/blacksmithing/blacksmithing_over.dds",
	},
	["CLOTHIER"] = {
		upTexture = "IIfA/assets/materials/clothier/clothier_up.dds",
		downTexture = "IIfA/assets/materials/clothier/clothier_down.dds",
		flash = "IIfA/assets/materials/clothier/clothier_over.dds",
	},
	["ENCHANTING"] = {
		upTexture = "IIfA/assets/materials/enchanting/enchanting_up.dds",
		downTexture = "IIfA/assets/materials/enchanting/enchanting_down.dds",
		flash = "IIfA/assets/materials/enchanting/enchanting_over.dds",
	},
	["PROVISIONING"] = {
		upTexture = "IIfA/assets/materials/provisioning/provisioning_up.dds",
		downTexture = "IIfA/assets/materials/provisioning/provisioning_down.dds",
		flash = "IIfA/assets/materials/provisioning/provisioning_over.dds",
	},
	["STYLE"] = {
		upTexture = "IIfA/assets/materials/style/style_up.dds",
		downTexture = "IIfA/assets/materials/style/style_down.dds",
		flash = "IIfA/assets/materials/style/style_over.dds",
	},
	["WOODWORKING"] = {
		upTexture = "IIfA/assets/materials/woodworking/woodworking_up.dds",
		downTexture = "IIfA/assets/materials/woodworking/woodworking_down.dds",
		flash = "IIfA/assets/materials/woodworking/woodworking_over.dds",
	},
	["WTRAIT"] = {
		upTexture = "IIfA/assets/materials/wtrait/wtrait_up.dds",
		downTexture = "IIfA/assets/materials/wtrait/wtrait_down.dds",
		flash = "IIfA/assets/materials/wtrait/wtrait_over.dds",
	},

	--miscellaneous
	["ARMORGLYPH"] = {
		upTexture = "IIfA/assets/miscellaneous/armorglyph/armorglyph_up.dds",
		downTexture = "IIfA/assets/miscellaneous/armorglyph/armorglyph_down.dds",
		flash = "IIfA/assets/miscellaneous/armorglyph/armorglyph_over.dds",
	},
	["AVAWEAPON"] = {
		upTexture = "IIfA/assets/miscellaneous/avaweapon/avaweapon_up.dds",
		downTexture = "IIfA/assets/miscellaneous/avaweapon/avaweapon_down.dds",
		flash = "IIfA/assets/miscellaneous/avaweapon/avaweapon_over.dds",
	},
	["BAIT"] = {
		upTexture = "IIfA/assets/miscellaneous/bait/bait_up.dds",
		downTexture = "IIfA/assets/miscellaneous/bait/bait_down.dds",
		flash = "IIfA/assets/miscellaneous/bait/bait_over.dds",
	},
	["GLYPHS"] = {
		upTexture = "IIfA/assets/miscellaneous/glyphs/glyphs_up.dds",
		downTexture = "IIfA/assets/miscellaneous/glyphs/glyphs_down.dds",
		flash = "IIfA/assets/miscellaneous/glyphs/glyphs_over.dds",
	},
	["JEWELRYGLYPH"] = {
		upTexture = "IIfA/assets/miscellaneous/jewelryglyph/jewelryglyph_up.dds",
		downTexture = "IIfA/assets/miscellaneous/jewelryglyph/jewelryglyph_down.dds",
		flash = "IIfA/assets/miscellaneous/jewelryglyph/jewelryglyph_over.dds",
	},
	["SOULGEM"] = {
		upTexture = "IIfA/assets/miscellaneous/soulgem/soulgem_up.dds",
		downTexture = "IIfA/assets/miscellaneous/soulgem/soulgem_down.dds",
		flash = "IIfA/assets/miscellaneous/soulgem/soulgem_over.dds",
	},
	["TOOL"] = {
		upTexture = "IIfA/assets/consumables/repair/repair_up.dds",
		downTexture = "IIfA/assets/consumables/repair/repair_down.dds",
		flash = "IIfA/assets/consumables/repair/repair_over.dds",
	},
	["TRASH"] = {
		upTexture = "IIfA/assets/miscellaneous/trash/trash_up.dds",
		downTexture = "IIfA/assets/miscellaneous/trash/trash_down.dds",
		flash = "IIfA/assets/miscellaneous/trash/trash_over.dds",
	},
	["TROPHY"] = {
		upTexture = "IIfA/assets/miscellaneous/trophy/trophy_up.dds",
		downTexture = "IIfA/assets/miscellaneous/trophy/trophy_down.dds",
		flash = "IIfA/assets/miscellaneous/trophy/trophy_over.dds",
	},
	["WEAPONGLYPH"] = {
		upTexture = "IIfA/assets/miscellaneous/weaponglyph/weaponglyph_up.dds",
		downTexture = "IIfA/assets/miscellaneous/weaponglyph/weaponglyph_down.dds",
		flash = "IIfA/assets/miscellaneous/weaponglyph/weaponglyph_over.dds",
	},

}


function IIfA.GetTextureMap()
	return IIfA.textureMap
end