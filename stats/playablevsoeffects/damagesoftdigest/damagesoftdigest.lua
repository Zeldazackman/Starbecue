function init()
  script.setUpdateDelta(5)

end

function update(dt)
  local powerMultiplier = status.statusProperty("statusDigestRate", 1)

  local health = world.entityHealth(entity.id())
  if health[1] > ( 0.01 * dt * powerMultiplier) then
    status.modifyResourcePercentage("health", -0.01 * dt * powerMultiplier)
  end
end

function uninit()

end
