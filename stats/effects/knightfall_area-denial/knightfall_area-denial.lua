function init()
  animator.setParticleEmitterOffsetRegion("static", mcontroller.boundBox())
  animator.setParticleEmitterActive("static", true)
  animator.playSound("static")
  
  local directives = config.getParameter("directives")
  if directives then
	effect.setParentDirectives(directives)
  end
	
  script.setUpdateDelta(7)
  
  local protectionModifier = config.getParameter("protectionModifier", 0.5)
  local physicalResistanceMod = config.getParameter("physicalResistanceMod", 0)
  local fireResistanceMod = config.getParameter("fireResistanceMod", 0)
  local electricResistanceMod = config.getParameter("electricResistanceMod", 0)
  local poisonResistanceMod = config.getParameter("poisonResistanceMod", 0)
  local iceResistanceMod = config.getParameter("iceResistanceMod", 0)
  
  self.jumpPenalty = config.getParameter("jumpPenalty", -0.45)
  self.speedModifier = config.getParameter("speedModifier", 0.25)
  self.groundModifier = config.getParameter("groundModifier", 0.15)
  self.airJumpModifier = config.getParameter("airJumpModifier", 0.25)
  
  local modifiers = {
    { stat = "protection", effectiveMultiplier = protectionModifier },
	{ stat = "jumpModifier", amount = self.jumpPenalty }
  }
  if physicalResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "physicalResistance", amount = physicalResistanceMod })
  end
  if fireResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "fireResistance", amount = fireResistanceMod })
  end
  if electricResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "electricResistance", amount = electricResistanceMod })
  end
  if poisonResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "poisonResistance", amount = poisonResistanceMod })
  end
  if iceResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "iceResistance", amount = iceResistanceMod })
  end
  
  self.modifierGroup = effect.addStatModifierGroup(modifiers)
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = self.groundModifier,
    speedModifier = self.speedModifier,
    airJumpModifier = self.airJumpModifier
  })
end

function uninit()
end