local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoMakeNonHostile", function(_,_)
		if (status.statusProperty("pvsoOriginalDamageTeam") == nil)
		or (entity.damageTeam() ~= { type = "ghostly", team = 1 })
		then
			status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		end
		monster.setAggressive(false)
		monster.setDamageOnTouch(false)
		monster.setDamageSources()
		monster.setDamageParts()
		monster.setPhysicsForces()
		monster.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("pvsoRestoreDamageTeam", function(_,_)
		monster.setDamageTeam(status.statusProperty("pvsoOriginalDamageTeam"))
	end)

end
