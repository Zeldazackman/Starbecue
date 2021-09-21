function everything_primary()
	message.setHandler("pvsoApplyStatusEffects", function(_,_, statlist)
		for stat, data in pairs(statlist) do
			status.addEphemeralEffect(stat, data.power, data.source)
		end
	end)

	message.setHandler("pvsoForceSit", function(_,_, data)
		status.setStatusProperty("pvsoForceSitData", data)
		status.setStatusProperty("pvsoDontTouchDoors", true)

		status.addEphemeralEffect("pvsoForceSit", 1, data.source)
	end)

	message.setHandler("getVSOseatInformation", function()
		return {
			mass = mcontroller.mass(),
			powerMultiplier = status.stat("powerMultiplier")
		}
	end)

	message.setHandler("pvsoSucc", function(_,_, data)
		status.setStatusProperty("pvsoSuccData", data)

		status.addEphemeralEffect("pvsoSucc", 1, data.source)
	end)

	message.setHandler("pvsoIsPreyEnabled", function(_,_, type)
		if (status.statusProperty("pvsoPreyEnabled") or {}).all == false then return false end

		if (status.statusProperty("pvsoPreyEnabled") or {})[type] == nil then
			local entityType = world.entityType(entity.id())
			local curEnabled = status.statusProperty("pvsoPreyEnabled") or {}
			local defaults = root.assetJson("/pvso_general.config:defaultPreyEnabled")
			status.setStatusProperty("pvsoPreyEnabled", sb.jsonMerge( defaults[entityType], curEnabled))
		end
		return status.statusProperty("pvsoPreyEnabled", {})[type]
	end)
end
