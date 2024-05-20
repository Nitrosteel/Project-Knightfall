function init()
  animator.setParticleEmitterOffsetRegion("rageflames", mcontroller.boundBox())
  animator.setParticleEmitterActive("rageflames", true)
  animator.playSound("rage", 0)
  animator.playSound("ragereverb", 0)
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
