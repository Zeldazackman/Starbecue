---@diagnostic disable: undefined-global

local _init = init
local _update = update
sizeRayHoldingShift = false
sizeRayWhichFireMode = "primary"

sizeRayFireModeMap = {
	primary = "Shrink",
	alt = "Grow"
}

local _sizeRayAnimator_setAnimationState
function sizeRayAnimator_setAnimationState(state, anim, force)
	if anim ~= "off" then
		anim = anim..sizeRayFireModeMap[sizeRayWhichFireMode]
	end
	_sizeRayAnimator_setAnimationState(state, anim, force)
end

function init()
	_init()

	if type(_sizeRayAnimator_setAnimationState) ~= "function" then
		_sizeRayAnimator_setAnimationState = animator.setAnimationState
		animator.setAnimationState = sizeRayAnimator_setAnimationState
	end
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
	if fireMode ~= "none" then
		sizeRayWhichFireMode = fireMode
	end
	-- this doesn't work because ChargeFire is a class and we need the individual instances
	if ChargeFire.chargeLevels ~= nil then
		animator.setGlobalTag("charge", ChargeFire:currentChargeLevel().level)
	end
	_update(dt, fireMode, shiftHeld, controls)
end
