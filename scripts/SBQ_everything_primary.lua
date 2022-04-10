function sbq.everything_primary()
	message.setHandler("sbqApplyStatusEffects", function(_,_, statlist)
		for statusEffect, data in pairs(statlist) do
			status.setStatusProperty(statusEffect, data.property)
			status.addEphemeralEffect(statusEffect, data.power, data.source)
		end
	end)
	message.setHandler("sbqRemoveStatusEffects", function(_,_, statlist)
		for _, statusEffect in ipairs(statlist) do
			status.removeEphemeralEffect(statusEffect)
		end
	end)
	message.setHandler("sbqRemoveStatusEffect", function(_,_, statusEffect)
		status.removeEphemeralEffect(statusEffect)
	end)

	message.setHandler("sbqApplyScaleStatus", function(_,_, scale)
		status.setStatusProperty("sbqScaling", scale)
		status.addEphemeralEffect("sbqScaling")
	end)

	message.setHandler("sbqForceSit", function(_,_, data)
		status.setStatusProperty("sbqForceSitData", data)
		status.setStatusProperty("sbqDontTouchDoors", true)

		status.addEphemeralEffect("sbqForceSit", 1, data.source)
	end)

	message.setHandler("sbqGetSeatInformation", function()
		return {
			mass = mcontroller.mass(),
			powerMultiplier = status.stat("powerMultiplier")
		}
	end)

	message.setHandler("sbqSucc", function(_,_, data)
		status.setStatusProperty("sbqSuccData", data)
		status.addEphemeralEffect("sbqSucc", 1, data.source)
	end)

	message.setHandler("sbqIsPreyEnabled", function(_,_, voreType)
		if (status.statusProperty("sbqPreyEnabled") or {}).enabled == false then return false end

		if (status.statusProperty("sbqPreyEnabled") or {})[voreType] == nil then
			local entityType = world.entityType(entity.id())
			local curEnabled = status.statusProperty("sbqPreyEnabled") or {}
			local defaults = root.assetJson("/sbqGeneral.config:defaultPreyEnabled")
			status.setStatusProperty("sbqPreyEnabled", sb.jsonMerge( defaults[entityType], curEnabled))
		end
		return (status.statusProperty("sbqPreyEnabled") or {})[voreType]
	end)

	message.setHandler("sbqSetVelocityAngle", function(_,_, data)
		status.setStatusProperty("sbqSetVelocityAngle", data)
		status.addEphemeralEffect("sbqSetVelocityAngle")
	end)
end
