---@diagnostic disable:undefined-global

function sbq.effectsPanel()
	if not sbq.predatorConfig or not sbq.predatorConfig.locations then return end
	effectsLayout:clearChildren()
	for i, location in ipairs(sbq.predatorConfig.listLocations or {}) do
		local locationData = sbq.predatorConfig.locations[location] or {}
		if (locationData.selectEffect or locationData.TF or locationData.eggify) then
			if locationData.TF and sbq.predatorSettings[location.."TF"] == nil then
				sbq.predatorSettings[location.."TF"] = false
				if sbq.deedUI then
					sbq.predatorSettings[location.."TFEnable"] = false
				end
			end
			if locationData.Eggify and sbq.predatorSettings[location.."Eggify"] == nil then
				sbq.predatorSettings[location.."Eggify"] = false
				if sbq.deedUI then
					sbq.predatorSettings[location.."EggifyEnable"] = false
				end
			end
			if sbq.deedUI then
				if locationData.selectEffect and sbq.predatorSettings[location.."NoneEnable"] == nil then
					sbq.predatorSettings[location.."NoneEnable"] = false
				end
				if locationData.selectEffect and sbq.predatorSettings[location.."HealEnable"] == nil then
					sbq.predatorSettings[location.."HealEnable"] = false
				end
				if locationData.selectEffect and sbq.predatorSettings[location.."SoftDigestEnable"] == nil then
					sbq.predatorSettings[location.."SoftDigestEnable"] = false
				end
				if locationData.selectEffect and sbq.predatorSettings[location.."DigestEnable"] == nil then
					sbq.predatorSettings[location.."DigestEnable"] = false
				end
			end

			effectsLayout:addChild({ type = "layout", mode = "horizontal", spacing = 0, children = {
				{ type = "label", text = " "..(locationData.name.." " or location), align = "right", inline = true, size = {40,10} },
				{
				{ size = 75},
				{
					{
						type = "checkBox", id = location.."None", checked = sbq.predatorSettings[location.."EffectSlot"] == "none" or sbq.predatorSettings[location.."EffectSlot"] == nil,
						radioGroup = location.."EffectGroup", value = "none",
						visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."Effect"] ~= ((locationData.none or {}).effect or (sbq.predatorConfig.effectDefaults or {}).none or "sbqRemoveBellyEffects") ) or (sbq.overrideSettings[location.."NoneEnable"] == false) or (sbq.overrideSettings.noneEnable == false))) or false,
						toolTip = ((locationData.none or {}).toolTip or "No effects will be applied to prey.")
					},{
						type = "checkBox", id = location.."Heal", checked = sbq.predatorSettings[location.."EffectSlot"] == "heal",
						radioGroup = location.."EffectGroup", value = "heal",
						visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."Effect"] ~= ((locationData.heal or {}).effect or (sbq.predatorConfig.effectDefaults or {}).heal or "sbqHeal")) or (sbq.overrideSettings[location.."HealEnable"] == false) or (sbq.overrideSettings.healEnable == false))) or false,
						toolTip = ((locationData.heal or {}).toolTip or "Prey within will be healed, boosted by your attack power.")
					},{
						type = "checkBox", id = location.."SoftDigest", checked = sbq.predatorSettings[location.."EffectSlot"] == "softDigest",
						radioGroup = location.."EffectGroup", value = "softDigest",
						visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."Effect"] ~= ((locationData.softDigest or {}).effect or (sbq.predatorConfig.effectDefaults or {}).softDigest or "sbqSoftDigest")) or (sbq.overrideSettings[location.."SoftDigestEnable"] == false) or (sbq.overrideSettings.softDigestEnable == false))) or false,
						toolTip = ((locationData.softDigest or {}).toolTip or "Prey within will be digested, boosted by your attack power.\nBut they will always retain 1HP.")
					},{
						type = "checkBox", id = location.."Digest", checked = sbq.predatorSettings[location.."EffectSlot"] == "digest",
						radioGroup = location.."EffectGroup", value = "digest",
						visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."Effect"] ~= ((locationData.digest or {}).effect or (sbq.predatorConfig.effectDefaults or {}).digest or "sbqDigest")) or (sbq.overrideSettings[location.."DigestEnable"] == false) or (sbq.overrideSettings.digestEnable == false))) or false,
						toolTip = ((locationData.digest or {}).toolTip or "Prey within will be digested, boosted by your attack power.")
					},
					{
						type = "checkBox", id = location.."TF", checked = sbq.predatorSettings[location.."TF"],
						visible = (locationData.TF and not (sbq.overrideSettings[location.."TF"] ~= nil)) or false,
						toolTip = ((locationData.TF or {}).toolTip or "Prey within will be transformed.")
					},
					{ type = "iconButton", id = location.."TFLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."Eggify", checked = sbq.predatorSettings[location.."Eggify"],
						visible = (locationData.eggify and not (sbq.overrideSettings[location.."Eggify"] ~= nil)) or false,
						toolTip = ((locationData.eggify or {}).toolTip or "Prey within will be trapped in an egg.")
					},
					{ type = "iconButton", id = location.."EggifyLocked", visible = false, image = "lockedDisabled.png"},
					{type = "spacer", size = 1}
				},
				{
					{
						type = "checkBox", id = location.."NoneEnable", toolTip = "Allows the NPC to choose to have no effect.",
						visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil) or (sbq.overrideSettings[location.."NoneEnable"] == false))) or false,
					},
					{ type = "iconButton", id = location.."NoneEnableLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."HealEnable",  toolTip = "Allows the NPC to choose to heal.",
						visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil) or (sbq.overrideSettings[location.."HealEnable"] == false))) or false,
					},
					{ type = "iconButton", id = location.."HealEnableLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."SoftDigestEnable",  toolTip = "Allows the NPC to choose to soft digest.",
						visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil) or (sbq.overrideSettings[location.."SoftDigestEnable"] == false))) or false,
					},
					{ type = "iconButton", id = location.."SoftDigestEnableLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."DigestEnable",  toolTip = "Allows the NPC to choose to digest.",
						visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil) or (sbq.overrideSettings[location.."DigestEnable"] == false))) or false,
					},
					{ type = "iconButton", id = location.."DigestEnableLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."TFEnable", toolTip = "Allows the NPC to choose to transform others.",
						visible = sbq.deedUI and (locationData.TF and not (sbq.overrideSettings[location.."TF"] ~= nil)) or false,
					},
					{ type = "iconButton", id = location.."TFEnableLocked", visible = false, image = "lockedDisabled.png"},
					{
						type = "checkBox", id = location.."EggifyEnable", toolTip = "Allows the NPC to choose trap others in eggs.",
						visible = sbq.deedUI and (locationData.eggify and not (sbq.overrideSettings[location.."Eggify"] ~= nil)) or false,
					},
					{ type = "iconButton", id = location.."EggifyEnableLocked", visible = false, image = "lockedDisabled.png"},
					{type = "spacer", size = 1}
				}}
			}})
			local noneButton = _ENV[location.."None"]
			local healButton = _ENV[location.."Heal"]
			local softDigestButton = _ENV[location.."SoftDigest"]
			local digestButton = _ENV[location.."Digest"]
			local eggifyButton = _ENV[location.."Eggify"]
			local transformButton = _ENV[location.."TF"]

			function noneButton:draw() sbq.drawEffectButton(noneButton, ((locationData.none or {}).icon or "/interface/scripted/sbq/sbqSettings/noEffect.png") ) end
			function healButton:draw() sbq.drawEffectButton(healButton, ((locationData.heal or {}).icon or "/interface/scripted/sbq/sbqSettings/heal.png")) end
			function softDigestButton:draw() sbq.drawEffectButton(softDigestButton, ((locationData.softDigest or {}).icon or "/interface/scripted/sbq/sbqSettings/softDigest.png")) end
			function digestButton:draw() sbq.drawEffectButton(digestButton, ((locationData.digest or {}).icon or "/interface/scripted/sbq/sbqSettings/digest.png")) end
			function eggifyButton:draw() sbq.drawEffectButton(eggifyButton, ((locationData.eggify or {}).icon or "/interface/scripted/sbq/sbqSettings/eggify.png")) end
			function transformButton:draw() sbq.drawEffectButton(transformButton, ((locationData.TF or {}).icon or "/interface/scripted/sbq/sbqSettings/transform.png")) end

			function noneButton:onClick() sbq.locationEffectButton(noneButton, location, locationData) end
			function healButton:onClick() sbq.locationEffectButton(healButton, location, locationData) end
			function softDigestButton:onClick() sbq.locationEffectButton(softDigestButton, location, locationData) end
			function digestButton:onClick() sbq.locationEffectButton(digestButton, location, locationData) end
		end
	end
end

function sbq.drawEffectButton(w, icon)
	local c = widget.bindCanvas(w.backingWidget) c:clear()
	local directives = ""
	if w.state == "press" then directives = "?brightness=-50" end
	local pos = vec2.mul(c:size(), 0.5)

	c:drawImageDrawable(icon..directives, pos, 1)
	if w.checked then
		c:drawImageDrawable(icon.."?outline=1;FFFFFFFF;FFFFFFFF"..directives, pos, 1)
	end
end

function sbq.locationEffectButton(button, location, locationData)
	local value = button:getGroupChecked().value
	local effect = (locationData[value] or {}).effect or (sbq.predatorConfig.effectDefaults or {})[value] or (sbq.config.effectDefaults or {})[value] or "sbqRemoveBellyEffects"
	sbq.globalSettings[location.."EffectSlot"] = value
	sbq.globalSettings[location.."Effect"] = effect
	if locationData.sided then
		local left =  sbq.predatorConfig.locations[location.."L"]
		local right =  sbq.predatorConfig.locations[location.."R"]
		if not right.selectEffect then
			sbq.globalSettings[location.."REffect"] = effect
		end
		if not left.selectEffect then
			sbq.globalSettings[location.."LEffect"] = effect
		end
	end
	sbq.saveSettings()
end
