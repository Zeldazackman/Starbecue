---@diagnostic disable: undefined-global

local _init = init
sizeRayMisfire = false

function init()
	_init()

	function ChargeFire:fire()
		if world.lineTileCollision(mcontroller.position(), self:firePosition()) then
			animator.setAnimationState("firing", "off")
			self.cooldownTimer = self.chargeLevel.cooldown or 0
			self:setState(self.cooldown, self.cooldownTimer)
			return
		end
		if math.random()<0.25 then
			sizeRayMisfire = true
			sizeRayHoldingShift = not sizeRayHoldingShift
		end
		if math.random()<0.25 then
			sizeRayMisfire = true
			local table = {"primary","alt"}
			local otherAbility = config.getParameter((table[math.random(2)]).."Ability")
			self.chargeLevel = copy(otherAbility.chargeLevels[math.random(2,#otherAbility.chargeLevels)])
		end

		if sizeRayMisfire then
			animator.playSound("error")
		end

		self.weapon:setStance(self.stances.fire)

		animator.setAnimationState("firing", self.chargeLevel.fireAnimationState or "fire")
		animator.playSound(self.chargeLevel.fireSound or "fire")

		self:fireProjectile()

		if self.stances.fire.duration then
			util.wait(self.stances.fire.duration)
		end

		self.cooldownTimer = (self.chargeLevel.cooldown or 0)

		self:setState(self.cooldown, self.cooldownTimer)
	end
end
