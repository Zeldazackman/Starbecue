local oldinit = init
sbq = {}

local _monster_setDamageTeam
function capture_monster_setDamageTeam(data)
	status.setStatusProperty("sbqOriginalDamageTeam", data)
	if (status.statusProperty( "sbqCurrentData" ) or {}).type ~= "prey" then
		_monster_setDamageTeam(data)
	end
end


function init()

	status.setStatusProperty( "sbqCurrentData", nil)

	message.setHandler("sbqPredatorDespawned", function (_,_, eaten, species, occupants)
		status.setStatusProperty("sbqPreyList", nil)

		status.setStatusProperty( "sbqCurrentData", nil)
	end)

	if type(_monster_setDamageTeam) ~= "function" then
		_monster_setDamageTeam = monster.setDamageTeam
		monster.setDamageTeam = capture_monster_setDamageTeam
	end

	message.setHandler("sbqMakeNonHostile", function(_,_)
		local damageTeam = entity.damageTeam()
		if (status.statusProperty("sbqOriginalDamageTeam") == nil) then
			status.setStatusProperty("sbqOriginalDamageTeam", damageTeam)
		end
		_monster_setDamageTeam({ type = "ghostly", team = damageTeam.team })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		local sbqOriginalDamageTeam = status.statusProperty("sbqOriginalDamageTeam")
		if sbqOriginalDamageTeam then
			_monster_setDamageTeam(sbqOriginalDamageTeam)
		end
	end)

	status.clearPersistentEffects("digestImmunity")
	status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	oldinit()
end
