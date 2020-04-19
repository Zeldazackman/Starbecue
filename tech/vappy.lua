local pressed = true
local rpcAutoDeploy = "send"

function update(args)
	if rpcAutoDeploy == "send" then
		rpcAutoDeploy = world.sendEntityMessage( entity.id(), "vappyautodeploy" )
	elseif rpcAutoDeploy ~= nil and rpcAutoDeploy:finished() then
		if rpcAutoDeploy:succeeded() then
			local result = rpcAutoDeploy:result()
			if result then args.moves["special1"] = true end
		else
			sb.logError( "Couldn't determine Vappy autodeploy setting." )
			sb.logError( rpcAutoDeploy:error() )
		end
		rpcAutoDeploy = nil
	end
	if args.moves["special1"] and not pressed then
		local position = mcontroller.position()
		world.spawnVehicle( "spovvaporeon", { position[1], position[2] + 1.5 }, { driver = entity.id() } )
	end
	pressed = args.moves["special1"]
end