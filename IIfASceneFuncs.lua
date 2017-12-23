-- scene related functions (show/hide/determine/register)


function IIfA:GetCurrentSceneName()
	local ret = ""

	-- [16:20] scene name: 65553, hidden: false
	if not SCENE_MANAGER or not SCENE_MANAGER:GetCurrentScene() then
		ret = "hud"
	elseif SCENE_MANAGER:GetCurrentScene().name == "hudui" then
		ret = "hud"
	else
		ret = SCENE_MANAGER:GetCurrentScene().name
	end

	if tostring(ret) == "65553" then ret = "hud" end

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
end

function IIfA:GetSceneSettings(sceneName)
	if sceneName == nil then
		sceneName = IIfA:GetCurrentSceneName()
	end

	local settings = IIfA:GetSettings().frameSettings

	if not settings[sceneName] then
		-- if we have to create a new set of scene info, register it in the scene change too, it'll be set again during next opening

		local scene = SCENE_MANAGER:GetScene(sceneName)
		scene:RegisterCallback("StateChange", function(...)
				IIfA:ProcessSceneChange(sceneName, ...)
			end)
		-- save the settings in the settings table, base it on HUD
		settings[sceneName] = ZO_DeepTableCopy(settings["hud"])
		settings[sceneName].hidden = true
		settings[sceneName].docked = false
	end

	return settings[sceneName]

end

function IIfA:ProcessSceneChange(sceneName, oldState, newState)
	if (tostring(newState) == "shown") then

		sceneName = IIfA:GetCurrentSceneName()

		local settings = IIfA:GetSceneSettings(sceneName)

		self:RePositionFrame(settings)
--[[
		IIFA_GUI.hidden = settings.hidden
		IIFA_GUI.locked = settings.locked
		IIFA_GUI.minimized = settings.minimized
		IIFA_GUI.docked = settings.docked

		if IIFA_GUI.minimized then
			IIfA:GUIMinimize(true)
		else
			IIfA:GuiReloadDimensions(settings, sceneName)
		end
		IIfA:GuiDock(settings.docked)
		IIFA_GUI:SetHidden(settings.hidden)
--]]
	end

	if (tostring(newState) == "hidden") then
		IIFA_GUI:SetHidden(true)
	end
end


function IIfA:SaveFrameInfo(calledFrom)
	if (calledFrom == "onHide") then return end

	local sceneName = IIfA:GetCurrentSceneName()
	local settings = IIfA:GetSceneSettings(sceneName)

    settings.hidden    	=  IIFA_GUI:IsControlHidden()
--    settings.locked    	=  IIFA_GUI.locked
--    settings.minimized 	=  IIFA_GUI.minimized
--	settings.docked		=  IIFA_GUI.docked

--	if sceneName ~= "hud" then
--		settings.docked = IIFA_GUI.docked
--	else
--		settings.docked = false
--	end

	if (not settings.docked and (calledFrom == "onMoveStop" or calledFrom == "onResizeStop")) then
    	settings.lastX	= IIFA_GUI:GetLeft()
    	settings.lastY	= IIFA_GUI:GetTop()
		if not settings.minimized then
			settings.width	= IIFA_GUI:GetWidth()
    		settings.height	= IIFA_GUI:GetHeight()
		end
	end
end

-- called only from bindings.xml on keypress
function IIfA:ToggleInventoryFrame()
	IIFA_GUI:SetHidden(not IIFA_GUI:IsControlHidden())
	if not IIFA_GUI:IsControlHidden() then
		-- get current camera mode so when we toggle off, we put it back to where it was (maybe, can think of some weird circumstances where it might screw it up)
		SetGameCameraUIMode(true)
		IIfA:GuiResizeScroll()
    	IIfA:UpdateScrollDataLinesData()
    	IIfA:UpdateInventoryScroll()
	end

	IIfA:SaveFrameInfo("ToggleInventoryFrame")
end


