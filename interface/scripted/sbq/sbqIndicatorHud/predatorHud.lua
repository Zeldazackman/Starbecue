
---@diagnostic disable:undefined-global


sbq = {
	sbqCurrentData = player.getProperty("sbqCurrentData") or {},
	refreshtime = 0,
	occupants = {
		total = 0
	}
}

function update()
	local dt = script.updateDt()
	sbq.checkRefresh(dt)
	sbq.updateBars()
end

function sbq.checkRefresh(dt)
	if sbq.refreshtime >= 0.1 and sbq.rpc == nil and sbq.sbqCurrentData.type == "driver" then
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
	occupantsArea:clearChildren()
	sbq.occupantList = {}
	sbq.listItems = {}
	sbq.refreshList = nil
end

sbq.occupantList = {}

function sbq.readOccupantData()
	if sbq.occupants.total > 0 then
		local last
		local y = 224
		for i, occupant in pairs(sbq.occupant) do
			local id = occupant.id
			if not ((i == "0") or (i == 0)) and (occupant ~= nil) and (id ~= nil) and (world.entityExists( id )) then
				y = y - 31
				local species = occupant.species
				last = id
				if sbq.occupantList[id] == nil then
					sbq.occupantList[id] = { layout = occupantsArea:addChild({ type = "layout", mode = "manual", position = {4,y}, size = {92,31}, children = {}})}
					sbq.occupantList[id].background = sbq.occupantList[id].layout:addChild({ type = "iconButton", noAutoCrop = true, image = "portrait.png" })
					sbq.occupantList[id].portrait = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."PortraitCanvas", position = {6,7}, size = {16,16} })
					sbq.occupantList[id].name = sbq.occupantList[id].layout:addChild({ type = "label", id = id.."Name", position = {33,9}, size = {47,10}, text = world.entityName( id ) })
					sbq.occupantList[id].healthbar = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."HealthBar", position = {23,0}, size = {61,5} })
					sbq.occupantList[id].progressbar = sbq.occupantList[id].layout:addChild({ type = "canvas", id = id.."ProgressBar", position = {23,25}, size = {61,5}})
					local occupantButton = sbq.occupantList[id].background
					function occupantButton:onClick()
						metagui.contextMenu({
							{"Let Out", function() world.sendEntityMessage( player.loungingIn(), "letout", id ) end}
						})
					end
				end

				if species == nil then
					sbq.setPortrait(sbq.occupantList[id].portrait, world.entityPortrait( id, "bust" ))
				else
					local skin = (occupant.smolPreyData.settings.skinNames or {}).head or "default"
					local directives = occupant.smolPreyData.settings.directives or ""
					sbq.setPortrait(sbq.occupantList[id].portrait, {{image = "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives, position = {0,0} }})
				end
			end
		end
		sbq.occupantList[last].background:setImage("portraitTop.png")
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

function sbq.setPortrait( canvasName, data )
	local canvas = widget.bindCanvas( canvasName.backingWidget )
	canvas:clear()
	for k,v in ipairs(data or {}) do
		local pos = v.position or {0, 0}
		canvas:drawImage(v.image, { pos[1]+8, pos[2]+2}, 1, nil, true )
	end
end


----------------------------------------------------------------------------------------------------------------

function settings:onClick()
	player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:settings" })
end
