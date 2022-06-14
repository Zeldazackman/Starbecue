require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {}
}

function state.stand.grab(args, tconfig)
	return true, function ()
		sbq.grab("hug")
		sb.logInfo("*grabbed*")
		sbq.doAnim("wrap", "wrap", true)

		sbq.eat( args.id, tconfig.location )

		sbq.timer("Wrap", 2, function()
		sb.logInfo("*wrapping*")
		end)
	end
end

function state.stand.escape(args, tconfig)
	return true, function ()
		sbq.doAnim("wrap", "unwrap", true)

		sbq.uneat( args.id )

		sbq.timer("unwrap", 2, function()
		sb.logInfo("*escaped*")
		end)
	end
end

_onDeath = sbq.onDeath
function sbq.onDeath(eaten)
	if not eaten then
		world.spawnItem("sbqMummyWraps", mcontroller.position() )
	end
	_onDeath(eaten)
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