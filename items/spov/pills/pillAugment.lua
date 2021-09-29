require "/scripts/augments/item.lua"

-- local globalConfig = root.assetJson("/pvso_general.config")

function apply(input)
	local modifier = config.getParameter("vsoModifier")
	if modifier then
		local output = Item.new(input) ---@diagnostic disable-line:undefined-global
		local dataPath = "scriptStorage.spov"
		local spovData = output:instanceValue(dataPath)
		if not spovData then
			dataPath = "spov"
			spovData = output:instanceValue(dataPath)
		end
		local species = spovData.type:gsub("^spov","")
		local speciesConfig = root.assetJson("/vehicles/spov/"..species.."/"..species..".vehicle")

		local allowed = speciesConfig.vso.allowedModifiers
		local default = speciesConfig.vso.defaultSettings
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
				if not allowed[k].min and not allowed[k].max then
					local found
					for _,a in allowed[k] do
						if a == k then found = true end
					end
					if not found then
						sb.logInfo("can't apply: "..k.." not valid (got \""..v.."\", allowed "..sb.printJson(allowed[k])..")")
						return nil
					end
				end
				if (currSettings[k] or default[k]) ~= v then
					current.settings[k] = v
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
