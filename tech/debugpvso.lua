local pressed = true
local rpcSettings = "send"
local settings = {
	bellyEffect = "",
	clickmode = "attack",
}

function update(args)
	if rpcSettings == "send" then
		rpcSettings = world.sendEntityMessage( entity.id(), "loadVSOsettings", "egg" )
	elseif rpcSettings ~= nil and rpcSettings:finished() then
		if rpcSettings:succeeded() then
			local result = rpcSettings:result()
			if result ~= nil then
				if result.autoDeploy then args.moves["special1"] = true end
				settings = sb.jsonMerge( settings, result ) -- any missing settings fill in from defaults
			end
		else
			sb.logError( "Couldn't load debug PVSO settings." )
			sb.logError( rpcSettings:error() )
		end
		rpcSettings = nil
	end
	if args.moves["special1"] and not pressed then
		local position = mcontroller.position()
		world.spawnVehicle( "spovegg", { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, direction = mcontroller.facingDirection()  } )
	end
	pressed = args.moves["special1"]
end
