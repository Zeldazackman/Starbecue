function init()
  script.setUpdateDelta(5)

end

function update(dt)
  local powerMultiplier = status.statusProperty("statusDigestRate", 1)

  status.modifyResourcePercentage("health", -0.01 * dt * powerMultiplier)

end

function uninit()

end
