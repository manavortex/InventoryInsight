-- scene related functions (show/hide/determine/register)


function IIfA:GetCurrentSceneName()
	local ret = IIfA.EMPTY_STRING

	-- [16:20] scene name: 65553, hidden: false
	if not SCENE_MANAGER or not SCENE_MANAGER:GetCurrentScene() then
		ret = "hud"
	elseif SCENE_MANAGER:GetCurrentScene().name == "hudui" then
		ret = "hud"
	else
		ret = SCENE_MANAGER:GetCurrentScene().name
	end

	if tostring(ret) == "65553" then ret = "hud" end
	if ret == "inventory" and QUICKSLOT_FRAGMENT:IsHidden() == false then
		ret = ret .. "_quickslots"
	end

	--IIfA:DebugOut("Get Current Scene Name: '<<1>>', '<<2>>'", SCENE_MANAGER:GetCurrentScene().name, ret)

	return ret
end

function IIfA:RegisterForSceneChanges()
	local scenes = IIfA:GetSettings().frameSettings
	for sceneName, settings in pairs(scenes) do
		if (sceneName ~= "hudui") then
			local scene = SCENE_MANAGER:GetScene(sceneName)
			if scene then
				scene:RegisterCallback("StateChange", function(...)
					IIfA:ProcessSceneChange(sceneName, ...)
				end)
			end
-- for reasons unknown, hudui doesn't always appear to be "found" for items in the list (get cur scene from scene_manager sometimes says hud, when it's hudui), force it to work same as HUD here
			if (sceneName == "hud") then
				local scene = SCENE_MANAGER:GetScene("hudui")
				scene:RegisterCallback("StateChange", function(...)
					IIfA:ProcessSceneChange(sceneName, ...)
				end)
			end
		end
	end

	INVENTORY_FRAGMENT:RegisterCallback("StateChange", function(...)
	   	IIfA:ProcessInventoryTabChange("", ...)
	end)
	CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", function(...)
	   	IIfA:ProcessInventoryTabChange("", ...)
	end)
	WALLET_FRAGMENT:RegisterCallback("StateChange", function(...)
	   	IIfA:ProcessInventoryTabChange("", ...)
	end)
	QUICKSLOT_FRAGMENT:RegisterCallback("StateChange", function(...)
	   	IIfA:ProcessInventoryTabChange("_quickslots", ...)
	end)

end

function IIfA:GetSceneSettings(sceneName)

	sceneName = sceneName or IIfA:GetCurrentSceneName()
	local settings = IIfA:GetSettings().frameSettings
	if not settings[sceneName] then
		-- if we have to create a new set of scene info, register it in the scene change too, it'll be set again during next opening

		local scene = SCENE_MANAGER:GetScene(sceneName)
		if scene then
			scene:RegisterCallback("StateChange", function(...)
					IIfA:ProcessSceneChange(sceneName, ...)
				end)
		end
		-- save the settings in the settings table, base it on HUD
		settings[sceneName] = ZO_DeepTableCopy(settings["hud"])
		settings[sceneName].hidden = true
		settings[sceneName].docked = false
	end

	IIfA:DebugOut("GetSceneSettings: name=<<1>>, hidden=<<2>>", sceneName, tostring(settings[sceneName].hidden))

	return settings[sceneName]

end


function IIfA:ProcessSceneChange(sceneName, oldState, newState)
	IIfA:DebugOut("ProcessSceneChange <<1>>: <<2>> -> <<3>>", sceneName, oldState, newState)
--	IIfA:DebugOut("scene.disallowEvaluateTransitionCompleteCount = <<1>>", SCENE_MANAGER:GetCurrentScene().disallowEvaluateTransitionCompleteCount)

	if SCENE_SHOWN == newState then
		sceneName = IIfA:GetCurrentSceneName()
		if sceneName == "inventory" then
			if not QUICKSLOT_FRAGMENT:IsHidden() then
				sceneName = sceneName .. "_quickslots"
			end
		end
		local settings = IIfA:GetSceneSettings(sceneName)
		self:RePositionFrame(settings)
	elseif SCENE_HIDDEN == newState then
		IIFA_GUI:SetHidden(true)
	end
end


function IIfA:ProcessInventoryTabChange(tabName, oldState, newState)
	IIfA:DebugOut("ProcessInventoryTabChange <<1>>: <<2>> -> <<3>>", tabName, oldState, newState)

	local sceneName = IIfA:GetCurrentSceneName()
	if sceneName:find("inventory") == nil then return end

	if newState == SCENE_SHOWN then
		sceneName = "inventory" .. tabName
		local settings = IIfA:GetSceneSettings(sceneName)
		self:RePositionFrame(settings)

	elseif SCENE_HIDDEN == newState then
		IIFA_GUI:SetHidden(true)
	end
end


function IIfA:SaveFrameInfo(calledFrom)
	IIfA:DebugOut("SaveFrameInfo: <<1>>", calledFrom)
	if (calledFrom == "onHide") then return end

	local sceneName = IIfA:GetCurrentSceneName()
	local settings = IIfA:GetSceneSettings(sceneName)

	settings.hidden = IIFA_GUI:IsControlHidden()
	IIfA:DebugOut("SaveFrameInfo scene: <<1>>, hidden=<<2>>", sceneName, tostring(settings.hidden))

	if (not settings.docked and (calledFrom == "onMoveStop" or calledFrom == "onResizeStop")) then
		settings.lastX	= IIFA_GUI:GetLeft()
		settings.lastY	= IIFA_GUI:GetTop()
		if not settings.minimized then
			settings.width	= IIFA_GUI:GetWidth()
			settings.height	= IIFA_GUI:GetHeight()
		end
	end
end

-- called from bindings.xml on keypress, and on /iifa toggle chat cmd
function IIfA:ToggleInventoryFrame()
	IIFA_GUI:SetHidden(not IIFA_GUI:IsControlHidden())
	if not IIFA_GUI:IsControlHidden() then
		-- IIfA:OnFirstInventoryOpen()
		-- get current camera mode so when we toggle off, we put it back to where it was (maybe, can think of some weird circumstances where it might screw it up)
		SetGameCameraUIMode(true)
		IIfA:GuiResizeScroll()
		IIfA:RefreshInventoryScroll()
	end
	if not IIfA.data.dontFocusSearch then
		IIfA.GUI_SearchBox:TakeFocus()
	end
	IIfA:SaveFrameInfo("ToggleInventoryFrame")
end


