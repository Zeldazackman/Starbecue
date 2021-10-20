function sbq.everything_primary()
	message.setHandler("sbqApplyStatusEffects", function(_,_, statlist)
		for stat, data in pairs(statlist) do
			status.addEphemeralEffect(stat, data.power, data.source)
		end
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

	message.setHandler("sbqIsPreyEnabled", function(_,_, type)
		if (status.statusProperty("sbqPreyEnabled") or {}).enabled == false then return false end

		if (status.statusProperty("sbqPreyEnabled") or {})[type] == nil then
			local entityType = world.entityType(entity.id())
			local curEnabled = status.statusProperty("sbqPreyEnabled") or {}
			local defaults = root.assetJson("/sbqGeneral.config:defaultPreyEnabled")
			status.setStatusProperty("sbqPreyEnabled", sb.jsonMerge( defaults[entityType], curEnabled))
		end
		return (status.statusProperty("sbqPreyEnabled") or {})[type]
	end)
end
