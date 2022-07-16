
function init()
	local preyEnabled = sb.jsonMerge(root.assetJson("/sbqGeneral.config").defaultPreyEnabled[world.entityType(entity.id())], status.statusProperty("sbqPreyEnabled") or {})
	local statModifierGroup = {}
	if preyEnabled.digestImmunity then
		table.insert(statModifierGroup, {stat = "digestionImmunity", amount = 1})
		if not preyEnabled.allowSoftDigest then
			table.insert(statModifierGroup, {stat = "softDigestImmunity", amount = 1})
		end
	end
	if preyEnabled.cumDigestImmunity then
		table.insert(statModifierGroup, {stat = "cumDigestImmunity", amount = 1})
		if not preyEnabled.allowCumSoftDigest then
			table.insert(statModifierGroup, {stat = "cumSoftDigestImmunity", amount = 1})
		end
	end
	if preyEnabled.milkDigestImmunity then
		table.insert(statModifierGroup, {stat = "milkDigestImmunity", amount = 1})
		if not preyEnabled.allowMilkSoftDigest then
			table.insert(statModifierGroup, {stat = "milkSoftDigestImmunity", amount = 1})
		end
	end
	effect.addStatModifierGroup(statModifierGroup)
	script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
