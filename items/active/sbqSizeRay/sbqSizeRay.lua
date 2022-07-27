---@diagnostic disable: undefined-global

local _init = init
local _update = update
sizeRayHoldingShift = false
sizeRayWhichFireMode = "none"

function init()
	_init()

	function ChargeFire:fireProjectile()

		local params = copy(self.chargeLevel.projectileParameters or {})
		if sizeRayHoldingShift then
			world.sendEntityMessage(entity.id(), "animOverrideScale", params.animOverrideScale, params.animOverrideScaleDuration )
			return
		end
		local projectileCount = self.chargeLevel.projectileCount or 1

		params.power = (self.chargeLevel.baseDamage * config.getParameter("damageLevelMultiplier")) / projectileCount
		params.powerMultiplier = activeItem.ownerPowerMultiplier()

		local spreadAngle = util.toRadians(self.chargeLevel.spreadAngle or 0)
		local totalSpread = spreadAngle * (projectileCount - 1)
		local currentAngle = totalSpread * -0.5
		for i = 1, projectileCount do
		  if params.timeToLive then
			params.timeToLive = util.randomInRange(params.timeToLive)
		  end

		  world.spawnProjectile(
			  self.chargeLevel.projectileType,
			  self:firePosition(),
			  activeItem.ownerEntityId(),
			  self:aimVector(currentAngle, self.chargeLevel.inaccuracy or 0),
			  false,
			  params
			)

		  currentAngle = currentAngle + spreadAngle
		end
	end
end


function update(dt, fireMode, shiftHeld, controls)
	sizeRayHoldingShift = shiftHeld
	sizeRayWhichFireMode = fireMode
	_update(dt, fireMode, shiftHeld, controls)
end
