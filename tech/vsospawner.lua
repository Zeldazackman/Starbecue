local pressedTime = 0
local rpc
local rpcCallback
local radialMenuOpen = false
local settings
local inited = false
local reload = false
local radialSelectionData = {}
local spawnCooldown = 0
local spawnedVehicle = nil

function init()
	message.setHandler( "refreshVSOsettings", function(_, _, newSettings) -- this only ever gets called when the prey despawns or other such occasions, we kinda hijack it for other purposes on the player
		settings = newSettings
		radialSelectionData.selection = settings.selected
	end)
end

function loadSettings()
	rpc = world.sendEntityMessage( entity.id(), "loadVSOsettings" )
	rpcCallback = function(result)
		settings = result
		if settings ~= nil and settings.selected ~= nil then
			radialSelectionData.selection = settings.selected
			if settings[settings.selected] ~= nil and settings[settings.selected].autoDeploy and not reload then
				spawnVSO(settings.selected)
			end
		end
	end
end

function update(args)
	if not inited then
		inited = true
		loadSettings()
	end
	if rpc ~= nil and rpc:finished() then
		if rpc:succeeded() then
			local result = rpc:result()
			if result ~= nil then
				rpcCallback(result)
			end
		else
			sb.logError( "Couldn't load VSO settings." )
			sb.logError( rpc:error() )
		end
		rpc = nil
	end
	if args.moves["special1"] then
		sb.setLogMap("pressedTime", pressedTime)
		pressedTime = pressedTime + args.dt
		if pressedTime >= 0.2 and not radialMenuOpen then -- long hold
			openRadialMenu()
			radialMenuOpen = true
		end
	elseif pressedTime > 0 or radialSelectionData.gotData then
		pressedTime = 0
		closeMenu()
		radialMenuOpen = false
		if not radialSelectionData.gotData and rpc == nil then
			rpc = world.sendEntityMessage( entity.id(), "getRadialSelection" )
			rpcCallback = function(data)
				if data.selection ~= nil and data.type == "vsoSelect" then
					radialSelectionData = data
					radialSelectionData.gotData = true
				end
			end
		end
		radialSelectionData.gotData = nil
		if radialSelectionData.selection ~= nil then
			if radialSelectionData.selection == "cancel" then
			elseif radialSelectionData.selection == "settings" then
				openSettingsMenu()
			else -- any other selection
				spawnVSO(radialSelectionData.selection)
			end
		end
	end
	spawnCooldown = math.max(0, spawnCooldown - args.dt)
	pressed = args.moves["special1"]
end

function spawnVSO(type)
	if (not spawnedVehicle or not world.entityExists(spawnedVehicle)) and spawnCooldown <= 0 then
		spawnCooldown = 1
		settings.selected = type
		world.sendEntityMessage( entity.id(), "playerSaveVSOsettings", settings )
		local position = mcontroller.position()
		spawnedVehicle = world.spawnVehicle( "spov"..type, { position[1], position[2] }, { driver = entity.id(), settings = sb.jsonMerge(settings[type] or {}, settings.global or {}), direction = mcontroller.facingDirection()  } )
	end
end

function openRadialMenu()
	radialSelectionData.selection = nil
	local options = {{
		name = "settings",
		icon = "/interface/title/modsover.png"
	}}
	if settings and settings.vsos then
		for vsoname, data in pairs(settings.vsos) do
			if data.enable then
				local skin = (settings[vsoname].skinNames or {}).head or "default"
				local directives = settings[vsoname].directives or ""
				if #options <= 10 then
					if data.index ~= nil and data.index+1 <= #options then
						table.insert(options, data.index+1, {
							name = vsoname,
							icon = "/vehicles/spov/"..vsoname.."/spov/"..skin.."/icon.png"..directives
						})
					else
						table.insert(options, {
							name = vsoname,
							icon = "/vehicles/spov/"..vsoname.."/spov/"..skin.."/icon.png"..directives
						})
					end
				end
			end
		end
	end

	world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoRadialMenu", {options = options, type = "vsoSelect"}, true )
end
function openSettingsMenu()
	world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoSpawnerSettings" )
end
function closeMenu()
	world.sendEntityMessage( entity.id(), "openPVSOInterface", "close" )
end
