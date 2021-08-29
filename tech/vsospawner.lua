local pressedTime = 0
local rpc
local rpcCallback
local activated = false
local radialMenuOpen = false
local settings
local inited = false

function update(args)
	if not inited then
		inited = true
		rpc = world.sendEntityMessage( entity.id(), "loadVSOsettings" )
		rpcCallback = function(result)
			settings = result
			if settings.autoDeploy then
				spawnVSO(settings.selected)
				activated = false
			end
		end
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
		rpcType = nil
	end
	if args.moves["special1"] then
		sb.setLogMap("pressedTime", pressedTime)
		pressedTime = pressedTime + args.dt
		if pressedTime >= 0.2 and not radialMenuOpen then -- long hold
			openRadialMenu()
			radialMenuOpen = true
		end
	elseif pressedTime > 0 then
		pressedTime = 0
		closeMenu()
		radialMenuOpen = false
		activated = true
		rpc = world.sendEntityMessage( entity.id(), "getRadialSelection" )
		rpcCallback = function(result)
			if result == "cancel" then
				-- do nothing
			elseif result == "settings" then
				openSettingsMenu()
			else -- any other selection
				spawnVSO()
			end
		end
	end
	pressed = args.moves["special1"]
end

function spawnVSO(type)
	settings.selected = type
	world.sendEntityMessage( entity.id(), "saveVSOsettings", settings )
	local position = mcontroller.position()
	world.spawnVehicle( "spov"..type, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings.vsos[type], direction = mcontroller.facingDirection()  } )
end

function openRadialMenu()
	local options = {{
		name = "settings",
		icon = "/interface/title/modsover.png"
	}}
	if settings and settings.vsos then
		for k, v in pairs(settings.vsos) do
			-- if k == current then
			-- 	table.insert(options, {
			-- 		name = "despawn",
			-- 		icon = "/interface/bookmarks/icons/beamparty.png"
			-- 	})
			if v.enabled ~= false then -- treat nil as true
				table.insert(options, {
					name = k,
					icon = "/vehicles/spov/"..k.."/"..k.."icon.png"
				})
			end
		end
	end

	world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoRadialMenu", {options = options}, true )
end
function openSettingsMenu()
	-- world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoSpawnerSettings" )
	sb.logInfo("TODO: vso spawner settings menu")
end
function closeMenu()
	world.sendEntityMessage( entity.id(), "openPVSOInterface", "close" )
end
