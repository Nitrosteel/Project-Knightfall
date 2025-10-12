function init()
  self.damageModifier = config.getParameter("damageModifier", 0.01)
  self.jumpPenalty = config.getParameter("jumpPenalty", -0.3)
  self.speedModifier = config.getParameter("speedModifier", 0.5)
  self.groundModifier = config.getParameter("groundModifier", 0.4)
  self.airJumpModifier = config.getParameter("airJumpModifier", 0.7)
  
  local directives = config.getParameter("directives")
  if directives then
	effect.setParentDirectives(directives)
  end

  self.statGroup = effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = self.damageModifier },
    { stat = "jumpModifier", amount = self.jumpPenalty }
  })
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