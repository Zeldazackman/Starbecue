
---@diagnostic disable:undefined-global


sbq = {
	sbqCurrentData = player.getProperty("sbqCurrentData") or {},
	refreshtime = 0,
	hudActions = root.assetJson("/interface/scripted/sbq/sbqIndicatorHud/hudActionScripts.config"),
	occupants = {
		total = 0
	}
}
function metagui.theme.drawFrame() -- maybe this could stop the background from drawing
end
local canvas = widget.bindCanvas(frame.backingWidget .. ".canvas")
canvas:clear()

function sbq.listSlots()
	occupantSlots:clearChildren()
	local y = 216
	for i = 1, sbq.occupants.total + 1 do
		y = y - 32
		occupantSlots:addChild({ type = "image", noAutoCrop = true, position = {80,y}, file = "portraitSlot.png" })
	end
end

sbq.listSlots()

function update()
	local dt = script.updateDt()
	sbq.checkRefresh(dt)
	sbq.updateBars()
	sbq.updateBellyEffectIcon()
end

function sbq.checkRefresh(dt)
	if sbq.refreshtime >= 0.1 and sbq.rpc == nil and sbq.sbqCurrentData.type == "driver" and player.loungingIn() ~= nil then
		sbq.rpc = world.sendEntityMessage( player.loungingIn(), "settingsMenuRefresh")
	elseif sbq.rpc ~= nil and sbq.rpc:finished() then
		if sbq.rpc:succeeded() then
			local result = sbq.rpc:result()
			if result ~= nil then
				sbq.settings = result.settings
				sbq.occupants = result.occupants
				sbq.occupant = result.occupant
				sbq.powerMultiplier = result.powerMultiplier
				sbq.refreshtime = 0
				sbq.refreshList = result.refreshList or sbq.refreshList
				sbq.locked = result.locked

				sbq.refreshListData()
				sbq.readOccupantData()

				sbq.refreshed = true
			end
		else
			sb.logError( "Couldn't refresh settings." )
			sb.logError( sbq.rpc:error() )
		end
		sbq.rpc = nil
	else
		sbq.refreshtime = sbq.refreshtime + dt
	end
end

function sbq.refreshListData()
	if not sbq.refreshList then return end
	sbq.listSlots()
	occupantsArea:clearChildren()
	sbq.occupantList = {}
	sbq.listItems = {}
	sbq.refreshList = nil
end


sbq.occupantList = {}

function sbq.readOccupantData()
	if sbq.occupants.total > 0 then
		local y = 224
		for i, occupant in pairs(sbq.occupant) do
			local id = occupant.id
			if not ((i == "0") or (i == 0)) and (occupant ~= nil) and (id ~= nil) and (world.entityExists( id )) then
				y = y - 32
				local species = occupant.species
				if sbq.occupantList[id] == nil then
					sbq.occupantList[id] = { layout = occupantsArea:addChild({ type = "layout", mode = "manual", position = {0,y}, size = {96,32}, children = {}})}
					sbq.occupantList[id].background = sbq.occupantList[id].layout:addChild({ type = "image", noAutoCrop = true, position = {0,0}, file = "portrait.png"  })
					sbq.occupantList[id].portrait = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."PortraitCanvas", position = {6,7}, size = {16,16} })
					sbq.occupantList[id].name = sbq.occupantList[id].layout:addChild({ type = "label", id = id.."Name", position = {33,9}, size = {47,10}, text = world.entityName( id ) })
					sbq.occupantList[id].healthbar = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."HealthBar", position = {23,0}, size = {61,5} })
					sbq.occupantList[id].progressbar = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."ProgressBar", position = {23,25}, size = {61,5}})
					local occupantButton = sbq.occupantList[id].portrait
					function occupantButton:onMouseButtonEvent(btn, down)
						if btn == 0 then -- left button
							if down then
								self.state = "press"
								self:captureMouse(btn)
							elseif self.state == "press" then
								self.state = "hover"
								self:releaseMouse()
								local actionList = {}
								for _, action in ipairs(sbq.hudActions.global) do
									table.insert(actionList, {action[1], function() sbq[action[2]](id) end})
								end
								if sbq.hudActions[sbq.sbqCurrentData.species] ~= nil then
									for _, action in ipairs(sbq.hudActions[sbq.sbqCurrentData.species]) do
										table.insert(actionList, {action[1], function() sbq[action[2]](id) end})
									end
								end

								metagui.contextMenu(actionList)
							end
						end
					end
				end

				if species == nil then
					sbq.setPortrait(sbq.occupantList[id].portrait, world.entityPortrait( id, "bust" ), {8,2})
				else
					local skin = (occupant.smolPreyData.settings.skinNames or {}).head or "default"
					local directives = occupant.smolPreyData.settings.directives or ""
					sbq.setPortrait(sbq.occupantList[id].portrait, {{image = "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives, position = {0,0} }}, {8,8})
				end
			end
		end
	else

	end
end

local HPPal = {"751900", "c61000", "f72929", "ffa5a5"}

local topBar = {
	empty = "/interface/scripted/sbq/barempty.png",
	full = "/interface/scripted/sbq/barfull.png",
	x = 0, y = 0, h = 5, w = 61,
	color = {"9e9e9e", "c4c4c4", "e4e4e4", "ffffff"}, -- defaults in barfull.png
}

local bottomBar = {
	empty = "/interface/scripted/sbq/barempty.png?flipy",
	full = "/interface/scripted/sbq/barfull.png?flipy",
	x = 0, y = 0, h = 5, w = 61,
	color = {"9e9e9e", "c4c4c4", "e4e4e4", "ffffff"}, -- defaults in barfull.png
}

function sbq.updateBars()
	if sbq.occupants.total > 0 and sbq.occupant ~= nil then
		for i, occupant in pairs(sbq.occupant) do
			if not ((i == "0") or (i == 0)) then
				local id = occupant.id
				if id ~= nil and world.entityExists(id) and sbq.occupantList[id] ~= nil then
					local health = world.entityHealth( id )
					sbq.progressBar( sbq.occupantList[id].healthbar, HPPal, health[1] / health[2], topBar )
					sbq.progressBar( sbq.occupantList[id].progressbar, occupant.progressBarColor, (occupant.progressBar or 0) / 100, bottomBar )
				end
			end
		end
	end
end

function sbq.replace(from, to)
	if to == nil or #to == 0 then return "" end
	local directive = "?replace;"
	for i, f in ipairs(from) do
		directive = directive .. f .. "=" .. to[i] .. ";"
	end
	return directive
end

function sbq.progressBar(canvas, color, percent, bar)
	local progressBar = widget.bindCanvas( canvas.backingWidget )
	progressBar:clear()

	local s = percent * bar.w
	if s < bar.w then
		progressBar:drawImageRect(
			bar.empty,
			{s, 0, bar.w, bar.h},
			{bar.x + s, bar.y, bar.x + bar.w, bar.y + bar.h}
		)
	end
	if s > 0 then
		progressBar:drawImageRect(
			bar.full .. sbq.replace(bar.color, color),
			{0, 0, s, bar.h},
			{bar.x, bar.y, bar.x + s, bar.y + bar.h}
		)
	end
end

function sbq.setPortrait( canvasName, data, offset )
	local canvas = widget.bindCanvas( canvasName.backingWidget )
	canvas:clear()
	for k,v in ipairs(data or {}) do
		local pos = v.position or {0, 0}
		canvas:drawImage(v.image, { pos[1]+offset[1], pos[2]+offset[2]}, 1, nil, true )
	end
end

local bellyEffectIconsTooltips = {
	sbqRemoveBellyEffects = { icon = "/stats/sbq/sbqRemoveBellyEffects/sbqRemoveBellyEffects.png", toolTip = "None", prev = "sbqSoftDigest", next = "sbqHeal" },
	sbqHeal = { icon = "/stats/sbq/sbqHeal/sbqHeal.png", toolTip = "Heal", prev = "sbqRemoveBellyEffects", next = "sbqDigest", display = true },
	sbqDigest = { icon = "/stats/sbq/sbqDigest/sbqDigest.png", toolTip = "Digest", prev = "sbqHeal", next = "sbqSoftDigest", display = true },
	sbqSoftDigest = { icon = "/stats/sbq/sbqSoftDigest/sbqSoftDigest.png", toolTip = "Soft Digest", prev = "sbqDigest", next = "sbqRemoveBellyEffects", display = true }
}
function sbq.adjustBellyEffect(direction)
	local newBellyEffect = bellyEffectIconsTooltips[(sbq.sbqSettings.global or {}).bellyEffect or "sbqRemoveBellyEffects" ][direction]
	if sbq.sbqSettings.global ~= nil then
		sbq.sbqSettings.global.bellyEffect = newBellyEffect
	else
		sbq.sbqSettings.global = {bellyEffect = newBellyEffect}
	end

	sbq.settings.bellyEffect = newBellyEffect

	player.setProperty("sbqSettings", sbq.sbqSettings)

	if player.loungingIn() ~= nil then
		world.sendEntityMessage(player.loungingIn(), "settingsMenuSet", sbq.settings )
	end
end

function sbq.updateBellyEffectIcon()
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}

	if (sbq.sbqSettings.global or {}).bellyEffect ~= nil then

		local effect = bellyEffectIconsTooltips[sbq.sbqSettings.global.bellyEffect]

		local appendTooltip = ""
		if sbq.sbqSettings.global.displayDigest and effect.display then
			appendTooltip = "Display "
		end

		bellyEffectIcon:setImage(effect.icon)
		bellyEffectIcon.toolTip = appendTooltip..effect.toolTip
	end
end

----------------------------------------------------------------------------------------------------------------

function settings:onClick()
	player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:settings" })
end

function prevBellyEffect:onClick()
	sbq.adjustBellyEffect("prev")
end

function bellyEffectIcon:onClick()
	local displayDigest = not sbq.sbqSettings.global.displayDigest
	sbq.sbqSettings.global.displayDigest = displayDigest
	sbq.settings.displayDigest = displayDigest

	player.setProperty("sbqSettings", sbq.sbqSettings)

	if player.loungingIn() ~= nil then
		world.sendEntityMessage(player.loungingIn(), "settingsMenuSet", sbq.settings )
	end
end

function nextBellyEffect:onClick()
	sbq.adjustBellyEffect("next")
end
