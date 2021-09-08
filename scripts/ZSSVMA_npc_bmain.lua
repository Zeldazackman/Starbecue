local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoMakeNonHostile", function(_,_)
		if (status.statusProperty("pvsoOriginalDamageTeam") == nil)
		or (entity.damageTeam() ~= { type = "ghostly", team = 1 })
		then
			status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		end
		status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		npc.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("pvsoRestoreDamageTeam", function(_,_)
		npc.setDamageTeam(status.statusProperty("pvsoOriginalDamageTeam"))
	end)

end
