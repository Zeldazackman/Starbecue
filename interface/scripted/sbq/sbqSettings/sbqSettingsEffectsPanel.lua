---@diagnostic disable:undefined-global
sbq.drawSpecialButtons = {}
function sbq.effectsPanel()
	if not sbq.predatorConfig or not sbq.predatorConfig.locations then return end
	locationTabLayout:clearChildren()
	locationTabLayout:addChild({ id = "locationTabField", type = "tabField", layout = "vertical", tabWidth = 40, tabs = {} })
	function locationTabField:onTabChanged(tab, previous)
		sbq.selectedLocationTab = tab
	end

	for i, location in ipairs(sbq.predatorConfig.listLocations or {}) do
		local locationData = sbq.predatorConfig.locations[location]
		if type(locationData) == "table" then
			sbq.locationDefaultSettings(locationData, location)

			local mainEffectLayout = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "horizontal", spacing = 0, children = {
					{
						{
							{
								type = "checkBox", id = location.."None", checked = sbq.predatorSettings[location.."EffectSlot"] == "none" or sbq.predatorSettings[location.."EffectSlot"] == nil,
								radioGroup = location.."EffectGroup", value = "none",
								visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."EffectSlot"] ~= "none" ) or (sbq.overrideSettings[location.."NoneEnable"] == false) or (sbq.overrideSettings.noneEnable == false))) or false,
								toolTip = ((locationData.none or {}).toolTip or "No effects will be applied to prey.")
							},{
								type = "checkBox", id = location.."Heal", checked = sbq.predatorSettings[location.."EffectSlot"] == "heal",
								radioGroup = location.."EffectGroup", value = "heal",
								visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."EffectSlot"] ~= "heal" ) or (sbq.overrideSettings[location.."HealEnable"] == false) or (sbq.overrideSettings.healEnable == false))) or false,
								toolTip = ((locationData.heal or {}).toolTip or "Prey within will be healed, boosted by your attack power.")
							},{
								type = "checkBox", id = location.."SoftDigest", checked = sbq.predatorSettings[location.."EffectSlot"] == "softDigest",
								radioGroup = location.."EffectGroup", value = "softDigest",
								visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."EffectSlot"] ~= "softDigest") or (sbq.overrideSettings[location.."SoftDigestEnable"] == false) or (sbq.overrideSettings.softDigestEnable == false))) or false,
								toolTip = ((locationData.softDigest or {}).toolTip or "Prey within will be digested, boosted by your attack power.\nBut they will always retain 1HP.")
							},{
								type = "checkBox", id = location.."Digest", checked = sbq.predatorSettings[location.."EffectSlot"] == "digest",
								radioGroup = location.."EffectGroup", value = "digest",
								visible = (locationData.selectEffect and not ((sbq.overrideSettings[location.."Effect"] ~= nil and sbq.overrideSettings[location.."Effect"] ~= "digest") or (sbq.overrideSettings[location.."DigestEnable"] == false) or (sbq.overrideSettings.digestEnable == false))) or false,
								toolTip = ((locationData.digest or {}).toolTip or "Prey within will be digested, boosted by your attack power.")
							},
						}, {}--[[,
						{
							{
								type = "checkBox", id = location.."NoneEnable", toolTip = "Allows the NPC to choose to have no effect.",
								visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."EffectSlot"] ~= nil) or (sbq.overrideSettings[location.."NoneEnable"] == false) or (sbq.overrideSettings.noneEnable == false))) or false,
							},
							{
								type = "checkBox", id = location.."HealEnable",  toolTip = "Allows the NPC to choose to heal.",
								visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."EffectSlot"] ~= nil) or (sbq.overrideSettings[location.."HealEnable"] == false) or (sbq.overrideSettings.healEnable == false))) or false,
							},
							{
								type = "checkBox", id = location.."SoftDigestEnable",  toolTip = "Allows the NPC to choose to soft digest.",
								visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."EffectSlot"] ~= nil) or (sbq.overrideSettings[location.."SoftDigestEnable"] == false) or (sbq.overrideSettings.softDigestEnable == false))) or false,
							},
							{
								type = "checkBox", id = location.."DigestEnable",  toolTip = "Allows the NPC to choose to digest.",
								visible = sbq.deedUI and (locationData.selectEffect and not ((sbq.overrideSettings[location.."EffectSlot"] ~= nil) or (sbq.overrideSettings[location.."DigestEnable"] == false) or (sbq.overrideSettings.digestEnable == false))) or false,
							},
						}]]
					},
					{type = "spacer", size = 1},
					{type = "label", align = "center", id = location.."EffectLabel", text = (sbq.config.bellyStatusEffectNames[sbq.getStatusEffectSlot(location, locationData)] or "No Effect")},
				}}
			} }

			local extraEffectLayout = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "vertical", spacing = 0, children = {
					{
						{
							type = "checkBox", id = location.."TF", checked = sbq.predatorSettings[location.."TF"],
							visible = (locationData.TF and not (sbq.overrideSettings[location.."TF"] ~= nil)) or false,
							toolTip = ((locationData.TF or {}).toolTip or "Prey within will be transformed.")
						},
						{
							type = "checkBox", id = location.."Eggify", checked = sbq.predatorSettings[location.."Eggify"],
							visible = (locationData.eggify and not (sbq.overrideSettings[location.."Eggify"] ~= nil)) or false,
							toolTip = ((locationData.eggify or {}).toolTip or "Prey within will be trapped in an egg.")
						},
					}--[[,
					{
						{
							type = "checkBox", id = location.."TFEnable", toolTip = "Allows the NPC to choose to transform others.",
							visible = sbq.deedUI and (locationData.TF and not (sbq.overrideSettings[location.."TF"] ~= nil)) or false,
						},
						{
							type = "checkBox", id = location.."EggifyEnable", toolTip = "Allows the NPC to choose trap others in eggs.",
							visible = sbq.deedUI and (locationData.eggify and not (sbq.overrideSettings[location.."Eggify"] ~= nil)) or false,
						},
					}]]
				}}
			}}
			local otherLayout = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "vertical", spacing = 0, children = {
					{
						{
							type = "checkBox", id = location.."Sounds", checked = sbq.globalSettings[location.."Sounds"],
							toolTip = "Will emit gurgling sounds when prey is within."
						},
						{ type = "label", text = "Gurgling Sounds" }
					}
				}}
			}}

			local modifiersLayout = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "vertical", spacing = 0, children = {
					{type = "label", text = "Size Modifiers", align = "center"},
					{
						{ type = "textBox", align = "center", id = location .. "VisualMin", toolTip = "Minimum Visual Occupancy"},
						{ type = "textBox", align = "center", id = location .. "VisualMax", toolTip = "Maximum Visual Occupancy"},
						{ type = "textBox", align = "center", id = location .. "Multiplier", toolTip = "Occupant Size Multiplier"},
					},
					{
						{ type = "checkBox", id = location .. "HammerspaceDisabled",
							checked = sbq.predatorSettings[location .. "HammerspaceDisabled"],
							toolTip = "Disallow hammerspace for this location when it is enabled.",
							visible = locationData.hammerspace or false
						},
						{ type = "label", text = "Disallow Hammerspace", visible = locationData.hammerspace or false}
					},
					{
						{ type = "checkBox", id = location .. "Compression", checked = sbq.predatorSettings[location.."Compression"], toolTip = "Prey will be compressed to a smaller size over time." },
						{ type = "label", text = "Compression"}
					}
				}}
			} }
			local difficultyMod = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "vertical", spacing = 0, children = {
					{type = "label", text = "Difficulty Mod", align = "center"},
					{ type = "textBox", align = "center", id = location .. "DifficultyMod", toolTip = "Make this location easier or harder relative to the main difficulty."},
				}}
			} }
			local absorbedPreyList
			local absorbedPreyPanel = { type = "panel", style = "flat", expandMode = {1,0}, children = {
				{ type = "layout", mode = "vertical", spacing = 0, children = {
					{ type = "label", text = "Absorbed Prey", align = "center" },
					{ type = "itemGrid", slots = 5, id = location.."ItemGrid" },
				}}
			} }
			if type(sbq.storedDigestedPrey[location]) == "table" then
				local players = {}
				local ocs = {}
				local other = {}
				local count = 0
				for uniqueId, item in pairs(sbq.storedDigestedPrey[location]) do
					count = count + 1
					if item.parameters.npcArgs.wasPlayer then
						table.insert(players, item)
					elseif (root.npcConfig(item.parameters.npcArgs.npcType).scriptConfig or {}).isOC then
						table.insert(ocs, item)
					else
						table.insert(other, item)
					end
				end
				absorbedPreyList = players
				util.appendLists(absorbedPreyList, ocs)
				util.appendLists(absorbedPreyList, other)
				absorbedPreyPanel.children[1].children[2].slots = (count+10)-((count+10)%5)
			end

			local tab = locationTabField:newTab({
				type = "tab", id = location .. "Tab", title = (locationData.name .. " " or location),
				contents = {
					{ type = "scrollArea", scrollBars = true, thumbScrolling = true, scrollDirections = {0,1}, children = {
						{ type = "panel", style = "convex", children = {
							mainEffectLayout,
							extraEffectLayout,
							otherLayout,
							modifiersLayout,
							difficultyMod,
							absorbedPreyPanel
						} }
					}}
				}
			})
			if i == 1 then
				sbq.selectedLocationTab = tab
			end

			local itemGrid = _ENV[location .. "ItemGrid"]
			for i, item in ipairs(absorbedPreyList or {}) do
				itemGrid:setItem(i, item)
			end

			local noneButton = _ENV[location.."None"]
			local healButton = _ENV[location.."Heal"]
			local softDigestButton = _ENV[location.."SoftDigest"]
			local digestButton = _ENV[location.."Digest"]
			local eggifyButton = _ENV[location.."Eggify"]
			local transformButton = _ENV[location .. "TF"]
			local effectLabel = _ENV[location.."EffectLabel"]

			function noneButton:draw() sbq.drawEffectButton(noneButton, ((locationData.none or {}).icon or "/interface/scripted/sbq/sbqSettings/noEffect.png") ) end
			function healButton:draw() sbq.drawEffectButton(healButton, ((locationData.heal or {}).icon or "/interface/scripted/sbq/sbqSettings/heal.png")) end
			function softDigestButton:draw() sbq.drawEffectButton(softDigestButton, ((locationData.softDigest or {}).icon or "/interface/scripted/sbq/sbqSettings/softDigest.png")) end
			function digestButton:draw() sbq.drawEffectButton(digestButton, ((locationData.digest or {}).icon or "/interface/scripted/sbq/sbqSettings/digest.png")) end
			function eggifyButton:drawSpecial() sbq.drawEffectButton(eggifyButton, ((locationData.eggify or {}).icon or "/interface/scripted/sbq/sbqSettings/eggify.png")) end
			function transformButton:drawSpecial() sbq.drawEffectButton(transformButton, ((locationData.TF or {}).icon or "/interface/scripted/sbq/sbqSettings/transform.png")) end
			sbq.drawSpecialButtons[location .. "TF"] = true
			sbq.drawSpecialButtons[location .. "Eggify"] = true

			function noneButton:onClick() sbq.locationEffectButton(noneButton, location, locationData, effectLabel) end
			function healButton:onClick() sbq.locationEffectButton(healButton, location, locationData, effectLabel) end
			function softDigestButton:onClick() sbq.locationEffectButton(softDigestButton, location, locationData, effectLabel) end
			function digestButton:onClick() sbq.locationEffectButton(digestButton, location, locationData, effectLabel) end

			local visualMin = _ENV[location .. "VisualMin"]
			local visualMax = _ENV[location .. "VisualMax"]
			local multiplier = _ENV[location .. "Multiplier"]
			local difficultyTextbox = _ENV[location.."DifficultyMod"]

			visualMin:setText(tostring(sbq.overrideSettings[location .. "VisualMin"] or sbq.predatorSettings[location .."VisualMin"] or 0))
			function visualMin:onEnter()
				sbq.numberBox(visualMin, "changePredatorSetting", location .. "VisualMin", "predatorSettings", "overrideSettings", (sbq.overrideSettings[location .. "VisualMin"] or locationData.minVisual or 0), math.min(sbq.predatorSettings[location .. "VisualMax"], (sbq.overrideSettings[location .. "VisualMax"] or locationData.max)))
				sbq.numberBoxColor(visualMax, math.max(sbq.predatorSettings[location.."VisualMin"], (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0)), (sbq.overrideSettings[location.."VisualMax"] or locationData.max) )
			end
			function visualMin:onTextChanged()
				sbq.numberBoxColor(visualMin, (sbq.overrideSettings[location .. "VisualMin"] or locationData.minVisual or 0), math.min(sbq.predatorSettings[location .. "VisualMax"], (sbq.overrideSettings[location .. "VisualMax"] or locationData.max)))
				sbq.numberBoxColor(visualMax, math.max(sbq.predatorSettings[location.."VisualMin"], (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0)), (sbq.overrideSettings[location.."VisualMax"] or locationData.max) )
			end
			function visualMin:onEscape() self:onEnter() end
			function visualMin:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
			sbq.numberBoxColor(visualMin, (sbq.overrideSettings[location .. "VisualMin"] or locationData.minVisual or 0), math.min(sbq.predatorSettings[location .. "VisualMax"], (sbq.overrideSettings[location .. "VisualMax"] or locationData.max)))

			visualMax:setText(tostring(sbq.overrideSettings[location .. "VisualMax"] or sbq.predatorSettings[location .."VisualMax"] or locationData.max or 0))
			function visualMax:onEnter()
				sbq.numberBox(visualMax, "changePredatorSetting", location .. "VisualMax", "predatorSettings", "overrideSettings", math.max(sbq.predatorSettings[location.."VisualMin"] or 0, (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0)), (sbq.overrideSettings[location.."VisualMax"] or locationData.max) )
				sbq.numberBoxColor(visualMin, (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0), math.min( sbq.predatorSettings[location.."VisualMax"], (sbq.overrideSettings[location.."VisualMax"] or locationData.max)) )
			end
			function visualMax:onTextChanged()
				sbq.numberBoxColor(visualMax, math.max(sbq.predatorSettings[location.."VisualMin"] or 0, (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0)), (sbq.overrideSettings[location.."VisualMax"] or locationData.max) )
				sbq.numberBoxColor(visualMin, (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0), math.min( sbq.predatorSettings[location.."VisualMax"], (sbq.overrideSettings[location.."VisualMax"] or locationData.max)) )
			end
			function visualMax:onEscape() self:onEnter() end
			function visualMax:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
			sbq.numberBoxColor(visualMax, math.max(sbq.predatorSettings[location.."VisualMin"] or 0, (sbq.overrideSettings[location.."VisualMin"] or locationData.minVisual or 0)), (sbq.overrideSettings[location.."VisualMax"] or locationData.max) )

			multiplier:setText(tostring(sbq.overrideSettings[location .. "Multiplier"] or sbq.predatorSettings[location .. "Multiplier"] or 1))
			function multiplier:onEnter() sbq.numberBox(self, "changeGlobalSetting", location .. "Multiplier", "globalSettings", "overrideSettings", 0) end
			function multiplier:onTextChanged() sbq.numberBoxColor(self, 0) end
			function multiplier:onEscape() self:onEnter() end
			function multiplier:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
			sbq.numberBoxColor(multiplier, 0)

			difficultyTextbox:setText(tostring(sbq.overrideSettings[location .. "DifficultyMod"] or sbq.predatorSettings[location .. "DifficultyMod"] or 0))
			function difficultyTextbox:onEnter() sbq.numberBox(self, "changeGlobalSetting", location .. "DifficultyMod", "globalSettings", "overrideSettings", sbq.overrideSettings[location.."DifficultyModMin"], sbq.overrideSettings[location.."DifficultyModMax"]) end
			function difficultyTextbox:onTextChanged() sbq.numberBoxColor(self, sbq.overrideSettings[location.."DifficultyModMin"], sbq.overrideSettings[location.."DifficultyModMax"]) end
			function difficultyTextbox:onEscape() self:onEnter() end
			function difficultyTextbox:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
			sbq.numberBoxColor(difficultyTextbox, sbq.overrideSettings[location.."DifficultyModMin"], sbq.overrideSettings[location.."DifficultyModMax"])
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

function sbq.locationEffectButton(button, location, locationData, effectLabel)
	local value = button:getGroupChecked().value
	sbq.globalSettings[location .. "EffectSlot"] = value
	sbq.predatorSettings[location.."EffectSlot"] = value
	local effect = sbq.getStatusEffectSlot(location, locationData)
	sbq.predatorSettings[location.."Effect"] = effect
	if locationData.sided then
		local left =  sbq.predatorConfig.locations[location.."L"]
		local right =  sbq.predatorConfig.locations[location.."R"]
		if not right.selectEffect then
			sbq.predatorSettings[location.."REffect"] = effect
		end
		if not left.selectEffect then
			sbq.predatorSettings[location.."LEffect"] = effect
		end
	end
	effectLabel:setText((sbq.config.bellyStatusEffectNames[effect] or "No Effect"))
	sbq.saveSettings()
end

function sbq.locationDefaultSettings(locationData,location)
	if locationData.TF and sbq.predatorSettings[location.."TF"] == nil then
		sbq.predatorSettings[location.."TF"] = false
		if sbq.deedUI then
			sbq.predatorSettings[location.."TFEnable"] = false
		end
	end
	if locationData.eggify and sbq.predatorSettings[location.."Eggify"] == nil then
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
	if sbq.predatorSettings[location.."VisualMax"] == nil then
		sbq.predatorSettings[location.."VisualMax"] = locationData.max or 0
	end
	sbq.globalSettings[location.."HammerspaceDisabled"] = sbq.globalSettings[location.."HammerspaceDisabled"] or false
	sbq.globalSettings[location.."Compression"] = sbq.globalSettings[location.."Compression"] or false
	sbq.globalSettings[location.."Sounds"] = sbq.globalSettings[location.."Sounds"] or false

end

local map = {
	heal = "Heal",
	none = "None",
	digest = "Digest",
	softDigest = "SoftDigest"
}

function sbq.getStatusEffectSlot(location, locationData)
	local value = sbq.globalSettings[location .. "EffectSlot"]
	local effect = "sbqRemoveBellyEffects"
	if value then
		effect = (locationData[value] or {}).effect or (sbq.predatorConfig.effectDefaults or {})[value] or
			(sbq.config.effectDefaults or {})[value] or "sbqRemoveBellyEffects"
		if (sbq.predatorConfig.overrideSettings or {})[location .. map[value] .. "Enable"] == false then
			effect = (sbq.predatorConfig.defaultSettings or {})[location .. "Effect"] or "sbqRemoveBellyEffects"
		end
	end
	return effect
end

function sbq.numberBox(textbox, settingsFunc, settingName, settings, overrideSettings, min, max )
	local value = tonumber(textbox.text)
	local isNumber = type(value) == "number"
	if isNumber and (sbq[overrideSettings] or {})[settingName] == nil then
		local newValue = math.min(math.max(value, (min or -math.huge)), (max or math.huge))
		textbox:setText(tostring(newValue))
		sbq[settingsFunc](settingName, newValue)
		sbq.numberBoxColor(textbox, min, max)
		sbq.saveSettings()
	else
		textbox:setText(tostring((sbq[overrideSettings] or {})[settingName] or (sbq[settings] or {})[settingName] or 0))
	end
end
function sbq.numberBoxColor(textbox, min, max)
	local value = tonumber(textbox.text)
	local isNumber = type(value) == "number"
	local color = "FFFFFF"
	if isNumber then
		if type(max) == "number" and value == max
		or type(min) == "number" and value == min
		then
			color = "FFFF00"
		elseif type(max) == "number" and type(min) == "number" then
			if value > min and value < max then
				color = "00FF00"
			end
		end
		if type(max) == "number" and value > max
		or type(min) == "number" and value < min
		then
			color = "FF0000"
		end
	else
		color = "FF0000"
	end
	textbox:setColor(color)
end

function sbq.dropdownButton(button, settingname, list, func, overrides)
	local contextMenu = {}
	for i, values in ipairs(list) do
		table.insert(contextMenu, { values[2],
			function ()
				sbq[func](settingname, values[1])
				button:setText(values[2])
			end
		})
	end
	if sbq[overrides][settingname] == nil then
		function button:onClick()
			metagui.contextMenu(contextMenu)
		end
	end
end
