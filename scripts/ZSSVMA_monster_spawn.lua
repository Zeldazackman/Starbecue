local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoMakeNonHostile", function(_,_)
		if (status.statusProperty("pvsoOriginalDamageTeam") == nil)
		or (entity.damageTeam().type ~= "ghostly")
		then
			status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		end
		monster.setDamageSources()
		monster.setPhysicsForces({})
		monster.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("pvsoRestoreDamageTeam", function(_,_)
		monster.setDamageTeam(status.statusProperty("pvsoOriginalDamageTeam"))
	end)

	if config.getParameter("preyEnabled") ~= nil then
		status.setStatusProperty("pvsoPreyEnabled", config.getParameter("preyEnabled"))
	end
end
