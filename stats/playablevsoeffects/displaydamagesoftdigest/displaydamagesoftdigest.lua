function init()
  script.setUpdateDelta(5)

  self.tickTime = 1.0
  self.cdt = 0 -- cumulative dt
  self.cdamage = 0
  self.powerMultiplier = effect.duration()
  status.removeEphemeralEffect("damagedigest")
  status.removeEphemeralEffect("damagesoftdigest")
  status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)

  self.cdt = self.cdt + dt
  if self.cdt < self.tickTime then return end -- wait until at least 1 second has passed

  local damagecalc = status.resourceMax("health") * 0.01 * self.powerMultiplier *  self.cdt + self.cdamage
  if damagecalc < 1 then return end -- wait until at least 1 damage will be dealt

  self.cdt = 0
  self.cdamage = damagecalc % 1

  local health = status.resource("health")
  if health > math.floor(damagecalc) then -- won't die from full damage
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = math.floor(damagecalc),
      damageSourceKind = "poison",
      sourceEntityId = entity.id()
    })
  elseif health > 1 then -- will die from full damage, but can take partial damage
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = health - 1,
      damageSourceKind = "poison",
      sourceEntityId = entity.id()
    })
  -- else
    -- no damage left to do
  end
end

function uninit()

end
