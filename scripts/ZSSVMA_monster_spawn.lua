local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoMakeNonHostile", function(_,_)
		status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		monster.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("pvsoRestoreDamageTeam", function(_,_)
		monster.setDamageTeam(status.statusProperty("pvsoOriginalDamageTeam"))
	end)

end
