local pressed = true
local rpcSettings = "send"
local settings = {
	bellyeffect = "",
	clickmode = "attack",
}

function update(args)
	if rpcSettings == "send" then
		rpcSettings = world.sendEntityMessage( entity.id(), "loadvappysettings" )
	elseif rpcSettings ~= nil and rpcSettings:finished() then
		if rpcSettings:succeeded() then
			local result = rpcSettings:result()
			if result ~= nil then
				if result.autodeploy then args.moves["special1"] = true end
				settings = sb.jsonMerge( settings, result ) -- any missing settings fill in from defaults
			end
		else
			sb.logError( "Couldn't load Vappy settings." )
			sb.logError( rpcSettings:error() )
		end
		rpcSettings = nil
	end
	if args.moves["special1"] and not pressed then
		local position = mcontroller.position()
		world.spawnVehicle( "spovvaporeon", { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings } )
	end
	pressed = args.moves["special1"]
end