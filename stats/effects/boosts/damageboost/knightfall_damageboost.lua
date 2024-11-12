function init()
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", amount = config.getParameter("powerAmount", 0)},
    {stat = "powerMultiplier", baseMultiplier = config.getParameter("powerBaseMultiplier", 1.0)},
    {stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerEffectiveMultiplier", 1.0)},
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
