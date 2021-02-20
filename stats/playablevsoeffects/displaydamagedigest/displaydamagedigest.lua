function init()
  script.setUpdateDelta(5)

  self.tickTime = 1.0
  self.cdt = 0 -- cumulative dt
  self.cdamage = 0
end

function update(dt)
  self.cdt = self.cdt + dt
  if self.cdt < self.tickTime then return end -- wait until at least 1 second has passed

  local damagecalc = status.resourceMax("health") * 0.01 * self.cdt + self.cdamage
  if damagecalc < 1 then return end -- wait until at least 1 damage will be dealt

  self.cdt = 0
  self.cdamage = damagecalc % 1
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = math.floor(damagecalc),
    damageSourceKind = "poison",
    sourceEntityId = entity.id()
  })
end

function uninit()

end
