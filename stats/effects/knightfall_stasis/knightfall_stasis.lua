function init()
  animator.setParticleEmitterOffsetRegion("stasisParticles", mcontroller.boundBox())
  animator.setParticleEmitterActive("stasisParticles", true)
  effect.setParentDirectives("fade=c7c7c7=0.4")
  animator.playSound("stasis_start")
  animator.playSound("stasis_loop", -1)

  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = 0},
	{stat = "jumpModifier", amount = 0}
  })
  
  mcontroller.setVelocity({0, 0})
end

function update(dt)
  animator.setAnimationRate(0)
  
  mcontroller.controlModifiers({
      facingSuppressed = true,
      groundMovementModifier = 0,
      speedModifier = 0,
      airJumpModifier = 0
    })
	
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
end

function onExpire()
  animator.setAnimationRate(1)
end
