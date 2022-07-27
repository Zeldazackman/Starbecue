require("/vehicles/sbq/sbq_main.lua")

state = {
	sarcophagus = {}
}

function state.sarcophagus.grab(args, tconfig)
	return true, function ()
		sbq.doAnim("doorState", "opened", true)

		sbq.eat( args.id, tconfig.location, args.size or 1 )

		sbq.timer("closeDoor", 2, function()
			sbq.doAnim("doorState", "close", true)
		end)
	end
end

function state.sarcophagus.escape(args, tconfig)
	return true, function ()
		sbq.doAnim("doorState", "opened", true)

		sbq.uneat( args.id )

		sbq.timer("closeDoor", 2, function()
			sbq.doAnim("doorState", "close", true)
		end)
	end
end
