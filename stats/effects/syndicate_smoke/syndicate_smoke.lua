function init()
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = config.getParameter("damageModifier", 0.01)},
    {stat = "jumpModifier", amount = -0.3}
  })

  effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")
end

function update(dt)
  mcontroller.controlModifiers({
	  groundMovementModifier = 0.4,
	  speedModifier = 0.5,
	  airJumpModifier = 0.7
  })
end

function uninit()
end
