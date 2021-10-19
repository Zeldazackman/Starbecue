require "/scripts/augments/item.lua"

-- local globalConfig =

function apply(input)
	local modifier = config.getParameter("sbqModifier")
	if modifier then
		local output = Item.new(input) ---@diagnostic disable-line:undefined-global
		local dataPath = "scriptStorage.vehicle"
		local sbqData = output:instanceValue(dataPath)
		if not sbqData then
			dataPath = "vehicle"
			sbqData = output:instanceValue(dataPath)
		end
		local species = sbqData.type
		local speciesConfig = root.assetJson("/vehicles/sbq/"..species.."/"..species..".vehicle")

		local allowed = speciesConfig.sbqData.allowedModifiers
		local default = sb.jsonMerge(root.assetJson("/sbqGeneral.config").defaultSettings, speciesConfig.sbqData.defaultSettings or {})
		local current = output:instanceValue("scriptStorage") or {}
		local currSettings = current.settings or {}
		if allowed then
			local changed = false
			for k,v in pairs(modifier) do
				if not allowed[k] then
					sb.logInfo("can't apply: not allowed")
					return nil
				end
				if allowed[k].min and allowed[k].min > v then
					sb.logInfo("can't apply: "..k.." too low ("..v.." smaller than minimum "..allowed[k]..")")
					return nil
				end
				if allowed[k].max and allowed[k].max < v then
					sb.logInfo("can't apply: "..k.." too high ("..v.." larger than maximum "..allowed[k]..")")
					return nil
				end
				if not allowed[k].min and not allowed[k].max and allowed[k] ~= "bool" then
					if not allowed[k][v] then
						sb.logInfo("can't apply: "..k.." not valid (got \""..v.."\", allowed "..sb.printJson(allowed[k])..")")
						return nil
					end
				end
				if (currSettings[k] or default[k]) ~= v then
					currSettings[k] = v
					current.settings = currSettings
					changed = true
				end
			end
			if changed then
				output:setInstanceValue("scriptStorage", current)
				return output:descriptor(), 1
			end
		end
	end
end
