sbq = {}
local _init = init
local _update = update

local interactive
local _npc_setInteractive
function capture_npc_setInteractive(bool)
	interactive = bool
	_npc_setInteractive(bool)
end
local _npc_setDamageTeam
function capture_npc_setDamageTeam(data)
	status.setStatusProperty("sbqOriginalDamageTeam", data)
	if (status.statusProperty( "sbqCurrentData" ) or {}).type ~= "prey" then
		_npc_setDamageTeam(data)
	end
end
require("/scripts/SBQ_immunities.lua")


function init()
	if type(_npc_setInteractive) ~= "function" then
		_npc_setInteractive = npc.setInteractive
		npc.setInteractive = capture_npc_setInteractive

		_npc_setDamageTeam = npc.setDamageTeam
		npc.setDamageTeam = capture_npc_setDamageTeam
	end

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		status.setStatusProperty( "sbqCurrentData", current)
		if current.type == "prey" then
			status.setStatusProperty("sbqDontTouchDoors", true)
		else
			status.setStatusProperty("sbqDontTouchDoors", false)
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
		if (status.statusProperty("sbqOriginalDamageTeam") == nil) then
			status.setStatusProperty("sbqOriginalDamageTeam", damageTeam)
		end
		_npc_setDamageTeam({ type = "ghostly", team = damageTeam.team })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		local sbqOriginalDamageTeam = status.statusProperty("sbqOriginalDamageTeam")
		if sbqOriginalDamageTeam then
			_npc_setDamageTeam(sbqOriginalDamageTeam)
		end
	end)

	status.setStatusProperty( "sbqCurrentData", nil)

	_init()

	sbq.handleImmunities()

	if not status.statusProperty("sbqDidVornyConvertCheck") then
		status.setStatusProperty("sbqDidVornyConvertCheck", true)
		if tenant ~= nil then
			local vornyConvertTable = {
				villager = "sbqVoreVillager",
				villageguard = "sbqVoreVillageGuard",
				villageguardcaptain = "sbqVoreVillageGuardCaptain"
			}
			local npcType = vornyConvertTable[npc.npcType()]
			if (math.random(8) == 8) and npcType ~= nil then
				tenant.setNpcType(npcType)
			end
		end
	end
end
