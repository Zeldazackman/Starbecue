function init()
  script.setUpdateDelta(5)
  self.powerMultiplier = effect.duration()
  self.digested = false
  status.removeEphemeralEffect("damagesoftdigest")
  status.removeEphemeralEffect("displaydamagesoftdigest")
  status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)

  local health = world.entityHealth(entity.id())
  if health[1] > ( 0.01 * dt * self.powerMultiplier) then
    status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)
  elseif not self.digested then
    self.digested = true
    self.rpc = world.sendEntityMessage(effect.sourceEntity(), "digest", entity.id())
  elseif self.rpc then
    status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)
  end
end

function uninit()

end
