function init()
  animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("icetrail", true)
  effect.setParentDirectives("fade=00BBFF=0.15")

  script.setUpdateDelta(7)
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.45}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.15,
      speedModifier = 0.25,
      airJumpModifier = 0.25
    })
end

function uninit()

end
