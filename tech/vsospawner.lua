local pressedTime = 0
local rpcSettings = "send"
local activated = false
local radialMenuOpen = false
local settings

function update(args)
	if rpcSettings == "send" then
		rpcSettings = world.sendEntityMessage( entity.id(), "loadVSOsettings" )
	elseif rpcSettings ~= nil and rpcSettings:finished() then
		if rpcSettings:succeeded() then
			local result = rpcSettings:result()
			if result ~= nil then
				settings = result
				if settings.autodeploy or activated then
					activate()
					activated = false
				end
			end
		else
			sb.logError( "Couldn't load VSO settings." )
			sb.logError( rpcSettings:error() )
		end
		rpcSettings = nil
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
		rpcSettings = "send" -- update selection
	end
	pressed = args.moves["special1"]
end

function activate()
	if not settings or settings.selected == "despawn" then return end
	if not settings.selected or settings.selected == "settings" then
		openSettingsMenu()
		return
	end

	local position = mcontroller.position()
	world.spawnVehicle( "spov"..settings.selected, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings.vsos[settings.selected] } )
end

function openRadialMenu()
	world.sendEntityMessage( entity.id(), "openInterface", "vsoRadialMenu", {}, true )
end
function openSettingsMenu()
	-- world.sendEntityMessage( entity.id(), "openInterface", "vsoSpawnerSettings" )
	sb.logInfo("TODO: vso spawner settings menu")
end
function closeMenu()
	world.sendEntityMessage( entity.id(), "openInterface", "close" )
end