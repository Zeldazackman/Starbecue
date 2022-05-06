sbq = {}
local _init = init
local _update = update

local interactive
local _npc_setInteractive
function capture_npc_setInteractive(bool)
	interactive = bool
	_npc_setInteractive(bool)
end

function init()
	_npc_setInteractive = npc.setInteractive
	npc.setInteractive = capture_npc_setInteractive

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		status.setStatusProperty( "sbqCurrentData", current)
		if current.type ~= "driver" then
			status.setStatusProperty("sbqDontTouchDoors", true)
		end
		if current.species ~= "sbqOccupantHolder" then
			_npc_setInteractive(false)
		end
		return {
			head = npc.getItemSlot("head") or false,
			chest = npc.getItemSlot("chest") or false,
			legs = npc.getItemSlot("legs") or false,
			back = npc.getItemSlot("back") or false,
			headCosmetic = npc.getItemSlot("headCosmetic") or false,
			chestCosmetic = npc.getItemSlot("chestCosmetic") or false,
			legsCosmetic = npc.getItemSlot("legsCosmetic") or false,
			backCosmetic = npc.getItemSlot("backCosmetic") or false,
			statusDirectives = status.statusProperty("speciesAnimOverrideDirectives"),
			effectDirectives = status.statusProperty("effectDirectives")
		}
	end)

	message.setHandler("sbqInteract", function(_,_, pred, predData)
		return interact({sourceId = pred, sourcePosition = world.entityPosition(pred), predData = predData})
	end)
	message.setHandler("sbqVehicleInteracted", function (_,_, args)
		world.sendEntityMessage(args.sourceId, "sbqPlayerInteract", interact(args), entity.id() )
	end)

	message.setHandler("sbqPredatorDespawned", function (_,_, eaten, species, occupants)
		_npc_setInteractive(interactive)
		status.setStatusProperty( "sbqCurrentData", nil)
	end)

	message.setHandler("sbqMakeNonHostile", function(_,_)
		local damageTeam = entity.damageTeam()
		if (status.statusProperty("sbqOriginalDamageTeam") == nil)
		or (damageTeam.type ~= "ghostly")
		then
			status.setStatusProperty("sbqOriginalDamageTeam", damageTeam)
		end
		npc.setDamageTeam({ type = "ghostly", team = damageTeam.team })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		local sbqOriginalDamageTeam = status.statusProperty("sbqOriginalDamageTeam")
		if sbqOriginalDamageTeam then
			npc.setDamageTeam(sbqOriginalDamageTeam)
		end
	end)

	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	end
	status.setStatusProperty( "sbqCurrentData", nil)

	_init()
end
