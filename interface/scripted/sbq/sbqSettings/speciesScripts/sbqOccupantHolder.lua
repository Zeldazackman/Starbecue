---@diagnostic disable: undefined-global

local genderList = {
	noChange = "No Change",
	swap = "Swap",
	random = "Random",
	male = "Male",
	female = "Female"
}
genderSwapButton:setText(genderList[sbq.predatorSettings.TFTG])

sbq.dropdownButton(genderSwapButton, "TFTG", {
	{ "noChange", "No Change" },
	{ "swap", "Swap" },
	{ "random", "Random" },
	{ "male", "Male" },
	{ "female", "Female"}
}, "changePredatorSetting", "overrideSettings")

if sbq.overrideSettings.TFTGEnable == false then
	genderswapPanel:setVisible(false)
end

scaleValue:setVisible(player.hasItem("sbqSizeRay"))
scaleValue:setText(tostring(sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1))
function scaleValue:onEnter() sbq.numberBox(scaleValue, "changeAnimOverrideSetting", "scale", "animOverrideSettings", "animOverrideOverrideSettings", math.max(sbq.animOverrideSettings.scaleMin or 0.1, (sbq.animOverrideOverrideSettings.scaleMin or 0.1)), (sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3) ) end
function scaleValue:onTextChanged() sbq.numberBoxColor(scaleValue, math.max(sbq.animOverrideSettings.scaleMin or 0.1, (sbq.animOverrideOverrideSettings.scaleMin or 0.1)), (sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3) ) end
function scaleValue:onEscape() self:onEnter() end
function scaleValue:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
sbq.numberBoxColor(scaleValue, math.max(sbq.animOverrideSettings.scaleMin or 0.1, (sbq.animOverrideOverrideSettings.scaleMin or 0.1)), (sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3) )


scaleValueMin:setText(tostring(sbq.animOverrideOverrideSettings.scaleMin or sbq.animOverrideSettings.scaleMin or 0.1))
function scaleValueMin:onEnter() sbq.numberBox(scaleValue, "changeAnimOverrideSetting", "scaleMin", "animOverrideSettings", "animOverrideOverrideSettings", (sbq.animOverrideOverrideSettings.scaleMin or 0.1), (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1) ) end
function scaleValueMin:onTextChanged() sbq.numberBoxColor(scaleValue, (sbq.animOverrideOverrideSettings.scaleMin or 0.1), (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1) ) end
function scaleValueMin:onEscape() self:onEnter() end
function scaleValueMin:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
sbq.numberBoxColor(scaleValue, (sbq.animOverrideOverrideSettings.scaleMin or 0.1), (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1) )


scaleValueMax:setText(tostring(sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3))
function scaleValueMax:onEnter() sbq.numberBox(scaleValue, "changeAnimOverrideSetting", "scaleMin", "animOverrideSettings", "animOverrideOverrideSettings", (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1), (sbq.animOverrideOverrideSettings.scaleMax or 10) ) end
function scaleValueMax:onTextChanged() sbq.numberBoxColor(scaleValue, (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1), (sbq.animOverrideOverrideSettings.scaleMax or 10) ) end
function scaleValueMax:onEscape() self:onEnter() end
function scaleValueMax:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end
sbq.numberBoxColor(scaleValue, (sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1), (sbq.animOverrideOverrideSettings.scaleMax or 10) )
