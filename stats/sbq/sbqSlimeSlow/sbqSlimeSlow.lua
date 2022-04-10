function init()
  local sbqSlimeSlowColor = status.statusProperty("sbqSlimeSlow") or "4C9FFFBc"
  --animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  --animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade="..sbqSlimeSlowColor.."=0.4")
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.20}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.3,
      speedModifier = 0.35,
      airJumpModifier = 0.50
    })
end

function uninit()

end
