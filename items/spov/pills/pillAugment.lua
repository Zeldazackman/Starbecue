require "/scripts/augments/item.lua"

-- local globalConfig = root.assetJson("/pvso_general.config")

function apply(input)
	sb.logInfo("start apply")
	sb.logInfo(sb.printJson(input))
	local modifier = config.getParameter("vsoModifier")
	if modifier then
		local output = Item.new(input) ---@diagnostic disable-line:undefined-global
		local dataPath = "scriptStorage.spov"
		local spovData = output:instanceValue(dataPath)
		if spovData then
			dataPath = "spov"
			spovData = output:instanceValue(dataPath)
		end
		sb.logInfo(sb.printJson(spovData))
		local species = spovData.type:sub("^spov","")
		local speciesConfig = root.assetJson("/vehicles/spov/"..species.."/"..species..".vehicle")

		local allowed = speciesConfig.vso.allowedModifiers
		local default = speciesConfig.vso.defaultModifiers
		local current = spovData.modifiers or {}
		if allowed then
			local changed = false
			for k,v in modifier do
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
				if (current[k] or default[k]) ~= v then
					if default[k] == v then
						current[k] = nil -- don't bother storing if it's equal to default
					else
						current[k] = v
					end
					changed = true
				end
			end
			if changed then
				output:setInstanceValue("settings", current)
				return output:descriptor(), 1
			end
		end
	end
	sb.logInfo("got to end")
end
