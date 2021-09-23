local pressedTime = 0
local rpc
local rpcCallback
local radialMenuOpen = false
local settings
local inited = false
local reload = false

function init()
	message.setHandler( "saveVSOsettings", function() -- this only ever gets called when the prey despawns or other such occasions, we kinda hijack it for other purposes on the player
		reload = true
		loadSettings()
	end)
end

function loadSettings()
	rpc = world.sendEntityMessage( entity.id(), "loadVSOsettings" )
	rpcCallback = function(result)
		settings = result
		if settings.selected ~= nil and settings[settings.selected].autoDeploy and not reload then
			spawnVSO(settings.selected)
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
				spawnVSO(result)
			end
		end
	end
	pressed = args.moves["special1"]
end

function spawnVSO(type)
	settings.selected = type
	world.sendEntityMessage( entity.id(), "playerSaveVSOsettings", settings )
	local position = mcontroller.position()
	world.spawnVehicle( "spov"..type, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = sb.jsonMerge(settings[type], settings.global), direction = mcontroller.facingDirection()  } )
end

function openRadialMenu()
	local options = {{
		name = "settings",
		icon = "/interface/title/modsover.png"
	}}
	if settings and settings.vsos then
		for vsoname, vsoenabled in pairs(settings.vsos) do
			-- if k == current then
			-- 	table.insert(options, {
			-- 		name = "despawn",
			-- 		icon = "/interface/bookmarks/icons/beamparty.png"
			-- 	})
			if vsoenabled then
				local skin = settings[vsoname].skinNames.head or "default"
				local directives = settings[vsoname].directives or ""

				table.insert(options, {
					name = vsoname,
					icon = "/vehicles/spov/"..vsoname.."/spov/"..skin.."/icon.png"..directives
				})
			end
		end
	end

	world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoRadialMenu", {options = options}, true )
end
function openSettingsMenu()
	world.sendEntityMessage( entity.id(), "openPVSOInterface", "vsoSpawnerSettings" )
end
function closeMenu()
	world.sendEntityMessage( entity.id(), "openPVSOInterface", "close" )
end
