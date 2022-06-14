require("/vehicles/sbq/sbq_main.lua")

state = {
	sarcophagus = {}
}

function state.sarcophagus.grab(args, tconfig)
	return true, function ()
		sbq.doAnim("doorState", "opened", true)

		sbq.eat( args.id, tconfig.location )

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

function sbq.otherLocationEffects(i, eid, health, bellyEffect, location )
	if (sbq.occupant[i].progressBar <= 0) and sbq.settings.trappedTF then
		sbq.loopedMessage("TF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
			if not immune then
				transformMessageHandler( eid , 3, { species = "sbqMummy" } )
			end
		end)
	end
end