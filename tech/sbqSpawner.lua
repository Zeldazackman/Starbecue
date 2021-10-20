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
	message.setHandler( "sbqRefreshSettings", function(_, _, newSettings) -- this only ever gets called when the prey despawns or other such occasions, we kinda hijack it for other purposes on the player
		settings = newSettings
	end)
end

function loadSettings()
	rpc = world.sendEntityMessage( entity.id(), "sbqLoadSettings" )
	rpcCallback = function(result)
		settings = result
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
			sb.logError( "Couldn't load SBQ settings." )
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
			rpc = world.sendEntityMessage( entity.id(), "sbqGetRadialSelection" )
			rpcCallback = function(data)
				if data.selection ~= nil and data.type == "sbqSelect" then
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
				spawnPredator(radialSelectionData.selection)
			end
		end
	end
	spawnCooldown = math.max(0, spawnCooldown - args.dt)
	pressed = args.moves["special1"]
end

function spawnPredator(pred)
	if (not spawnedVehicle or not world.entityExists(spawnedVehicle)) and spawnCooldown <= 0 then
		spawnCooldown = 1
		spawnedVehicle = world.spawnVehicle( pred, mcontroller.position(), { driver = entity.id(), settings = settings[pred], direction = mcontroller.facingDirection()  } )
	end
end

function openRadialMenu()
	radialSelectionData.selection = nil
	local options = {{
		name = "settings",
		icon = "/interface/title/modsover.png"
	}}
	if settings and settings.types then
		for pred, data in pairs(settings.types) do
			if data.enable then
				local skin = (settings[pred].skinNames or {}).head or "default"
				local directives = settings[pred].directives or ""
				if #options <= 10 then
					if data.index ~= nil and data.index+1 <= #options then
						table.insert(options, data.index+1, {
							name = pred,
							icon = "/vehicles/sbq/"..pred.."/skins/"..skin.."/icon.png"..directives
						})
					else
						table.insert(options, {
							name = pred,
							icon = "/vehicles/sbq/"..pred.."/skins/"..skin.."/icon.png"..directives
						})
					end
				end
			end
		end
	end

	world.sendEntityMessage( entity.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "sbqSelect"}, true )
end
function openSettingsMenu()
	world.sendEntityMessage( entity.id(), "sbqOpenInterface", "sbqSpawnerSettings" )
end
function closeMenu()
	world.sendEntityMessage( entity.id(), "sbqOpenInterface", "sbqClose" )
end
