
---@diagnostic disable:undefined-global


sbq = {
	sbqCurrentData = player.getProperty("sbqCurrentData") or {},
	refreshtime = 0,
	hudActions = root.assetJson("/interface/scripted/sbq/sbqIndicatorHud/hudActionScripts.config"),
	config = root.assetJson("/sbqGeneral.config"),
	occupants = {
		total = 0
	}
}
function metagui.theme.drawFrame() -- maybe this could stop the background from drawing
end
local canvas = widget.bindCanvas(frame.backingWidget .. ".canvas")
canvas:clear()

require("/scripts/SBQ_RPC_handling.lua")
require("/scripts/speciesAnimOverride_player_species.lua")

function init()
	local sbqData = player.getProperty("sbqSettings") or {}
	if sbqData.global == nil then
		sbqData.global = {}
		player.setProperty("sbqSettings", sbqData)
	end
end

function sbq.listSlots()
	occupantSlots:clearChildren()
	local y = 217
	local slots = 7
	if sbq.sbqCurrentData.species == "sbqOccupantHolder" then
		slots = 8
	end
	for i = 1, sbq.occupants.total + 1 do
		if i <= slots then
			y = y - 25
			occupantSlots:addChild({ type = "image", noAutoCrop = true, position = {80,y}, file = "portraitSlot.png" })
		end
	end
end

sbq.listSlots()

function update()
	local dt = script.updateDt()
	sbq.checkRefresh(dt)
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)
	sbq.updateBars()
end

function sbq.checkRefresh(dt)
	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}
	if sbq.sbqCurrentData.type == "driver" then
		sbq.loopedMessage("checkRefresh", sbq.sbqCurrentData.id, "settingsMenuRefresh", {}, function (result)
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
		end )
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
		local playerSpecies = (sbq.sbqCurrentData or {}).species

		if playerSpecies == "sbqOccupantHolder" then
			local maybeSpecies = player.species()
			if type(sbq.hudActions[maybeSpecies]) == "table" then
				playerSpecies = maybeSpecies
			end
		end

		for i, occupant in pairs(sbq.occupant) do
			local id = occupant.id
			if ((not ((i == "0") or (i == 0))) or sbq.sbqCurrentData.species == "sbqOccupantHolder") and (occupant ~= nil) and (type(id) == "number") and (world.entityExists( id )) then
				y = y - 25
				local species = occupant.species
				if type(sbq.occupantList[id]) ~= "table" then
					sbq.occupantList[id] = { layout = occupantsArea:addChild({ type = "layout", mode = "manual", position = {0,y}, size = {96,24}, children = {
						{ type = "image", noAutoCrop = true, position = {0,0}, file = "portrait.png"  },
						{ type = "canvas", id = id.."PortraitCanvas", position = {8,4}, size = {16,16} },
						{ type = "label", id = id.."Name", position = {32,8.5}, size = {48,10}, text = world.entityName( id ) },
						{ type = "canvas", id = id.."ProgressBar", position = {23,0}, size = {61,5} },
						{ type = "canvas", id = id.."HealthBar", position = {23,19}, size = {61,5}},
						{ type = "iconButton", id = id.."ActionButton", noAutoCrop = true, position = {0,0}, image = "portrait.png?setcolor=FFFFFF?multiply=00000001"  }
					}})}
					sbq.occupantList[id].portrait = _ENV[id.."PortraitCanvas"]
					sbq.occupantList[id].healthbar = _ENV[id.."HealthBar"]
					sbq.occupantList[id].progressbar = _ENV[id.."ProgressBar"]
					sbq.occupantList[id].actionButton = _ENV[id.."ActionButton"]

					local occupantButton = sbq.occupantList[id].actionButton
					function occupantButton:onClick()
						local actionList = {}
						if world.entityType(id) == "npc" then
							table.insert(actionList, {"Interact", function() sbq.npcInteract(id, i) end})
						end
						for _, action in ipairs(sbq.hudActions.global) do
							if action.locations == nil or sbq.checkOccupantLocation(occupant.location, action.locations) then
								table.insert(actionList, {action.name, function() sbq[action.script](id, i) end})
							end
						end
						if type(sbq.hudActions[playerSpecies]) == "table" then
							for _, action in ipairs(sbq.hudActions[playerSpecies]) do
								if action.locations == nil or sbq.checkOccupantLocation(occupant.location, action.locations) then
									table.insert(actionList, {action.name, function() sbq[action.script](id, i) end})
								end
							end
						end
						metagui.contextMenu(actionList)
					end
				end

				if species == nil or species == "sbqOccupantHolder" then
					sbq.setPortrait(sbq.occupantList[id].portrait, world.entityPortrait( id, "bust" ), {8,2})
				else
					local skin = (occupant.smolPreyData.settings.skinNames or {}).head or "default"
					local directives = occupant.smolPreyData.settings.directives or ""
					sbq.setPortrait(sbq.occupantList[id].portrait, {{image = "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives, position = {0,0} }}, {8,8})
				end
			end
		end
	end
end

function sbq.checkOccupantLocation(occupantLocation, locations)
	for i, location in ipairs(locations) do
		if occupantLocation == location then return true end
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
			if ((not ((i == "0") or (i == 0))) or sbq.sbqCurrentData.species == "sbqOccupantHolder") then
				local id = occupant.id
				if type(id) == "number" and world.entityExists(id) and sbq.occupantList[id] ~= nil then
					local health = world.entityHealth( id )
					sbq.progressBar( sbq.occupantList[id].healthbar, HPPal, health[1] / health[2], bottomBar )
					sbq.progressBar( sbq.occupantList[id].progressbar, occupant.progressBarColor, (occupant.progressBar or 0) / 100, topBar )
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

function sbq.changeEscapeModifier(inc)
	sbq.sbqSettings.global.escapeDifficulty = (sbq.sbqSettings.global.escapeDifficulty or 0) + inc
	escapeValue:setText(tostring(sbq.sbqSettings.global.escapeDifficulty or 0))

	sbq.saveSettings()
end

function sbq.saveSettings()
	player.setProperty("sbqSettings", sbq.sbqSettings)
	sbq.settings = sb.jsonMerge(sbq.settings, sbq.sbqSettings.global)

	if sbq.sbqCurrentData.type == "driver" and type(sbq.sbqCurrentData.id) == "number" and world.entityExists(sbq.sbqCurrentData.id) then
		world.sendEntityMessage(sbq.sbqCurrentData.id, "settingsMenuSet", sbq.settings )
	end
end

----------------------------------------------------------------------------------------------------------------

function settings:onClick()
	player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:settings" })
end

function decEscape:onClick()
	sbq.changeEscapeModifier(-1)
end

function incEscape:onClick()
	sbq.changeEscapeModifier(1)
end

function impossibleEscape:onClick()
	sbq.sbqSettings.global.impossibleEscape = impossibleEscape.checked

	sbq.saveSettings()
end
