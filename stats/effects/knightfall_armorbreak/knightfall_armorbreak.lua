function init()
  animator.burstParticleEmitter("debris")
  animator.playSound("break")
  self.border = config.getParameter("border")

  if self.border then
    effect.setParentDirectives("border=" .. self.border)
  end

  local protectionModifier = config.getParameter("protectionModifier", 0.5)
  local physicalResistanceMod = config.getParameter("physicalResistanceMod", 0)
  local maxHealthModifier = config.getParameter("maxHealthModifier", 1.0)

  local modifiers = {
    { stat = "protection", effectiveMultiplier = protectionModifier }
  }
  if physicalResistanceMod ~= 0 then
    table.insert(modifiers, { stat = "physicalResistance", amount = physicalResistanceMod })
  end
  if maxHealthModifier ~= 1.0 then
    table.insert(modifiers, { stat = "maxHealth", effectiveMultiplier = maxHealthModifier })
  end

  self.modifierGroup = effect.addStatModifierGroup(modifiers)
end

function update(dt)
end

function uninit()
end