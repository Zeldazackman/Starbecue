function init()
  script.setUpdateDelta(5)
  self.powerMultiplier = effect.duration()

  status.removeEphemeralEffect("damagesoftdigest")
  status.removeEphemeralEffect("displaydamagesoftdigest")
  status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)

  status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)

end

function uninit()

end
