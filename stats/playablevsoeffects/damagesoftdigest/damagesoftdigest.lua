function init()
  script.setUpdateDelta(5)

end

function update(dt)
  local health = world.entityHealth(entity.id())
  if health[1] > ( 0.01 * dt ) then
    status.modifyResourcePercentage("health", -0.01 * dt)
  end
end

function uninit()

end
