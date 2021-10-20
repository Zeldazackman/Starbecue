local oldinit = init
sbq = {}

function init()
	oldinit()

	message.setHandler("sbqMakeNonHostile", function(_,_)
		if (status.statusProperty("sbqOriginalDamageTeam") == nil)
		or (entity.damageTeam().type ~= "ghostly")
		then
			status.setStatusProperty("sbqOriginalDamageTeam", entity.damageTeam())
		end
		monster.setDamageSources()
		monster.setPhysicsForces({})
		monster.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		monster.setDamageTeam(status.statusProperty("sbqOriginalDamageTeam"))
	end)

	if config.getParameter("sbqPreyEnabled") ~= nil then
		status.setStatusProperty("sbqPreyEnabled", config.getParameter("sbqPreyEnabled"))
	end
end
