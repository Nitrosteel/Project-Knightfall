function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterActive("energy", true)
  animator.playSound("recharge", -1)
  local directives = config.getParameter("directives")
  
  script.setUpdateDelta(5)

  if directives then
	effect.setParentDirectives(directives)
  end
end

function update(dt)

end

function uninit()
  
end
