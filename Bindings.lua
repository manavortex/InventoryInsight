
local IIfA = IIfA

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_INVENTORY_FRAME", "Toggle Inventory Frame")


function IIfA.IN2FrameToggle_Temp()
 	if(IN2_INVENTORY_FRAME:IsHidden())then
		local curScene = SCENE_MANAGER.currentScene
        IIfA.IN2_StatusAlert("[IIfA]:InventoryFrameVisibleInScene["..curScene.name.."]")
        IIfA.settings.in2InventoryFrameScenes[curScene.name] = true;
		IIfA.IN2_ToggleInventoryFrame(curScene, nil, "showing")
	else
		local curScene = SCENE_MANAGER.currentScene
        IIfA.IN2_StatusAlert("[IIfA]:InventoryFrameHiddenInScene["..curScene.name.."]")
        IIfA.settings.in2InventoryFrameScenes[curScene.name] = false;
		IIfA.IN2_ToggleInventoryFrame(curScene, nil, "hiding")
	end

end
