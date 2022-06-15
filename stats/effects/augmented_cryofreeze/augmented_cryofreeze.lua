require "/scripts/interp.lua"

function init()
  script.setUpdateDelta(1)
  
  animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("icetrail", true)
  animator.stopAllSounds("loop")
  animator.setSoundVolume("loop", 0)
  animator.playSound("loop", -1)
  
  color = config.getParameter("color")
  
  startDuration = effect.duration()
  
  buildupTime = config.getParameter("buildup") * startDuration
  buildupTimer = 1
  
  restore = config.getParameter("restore")
  
  modifiers = config.getParameter("modifiers") or {}
  groupId = effect.addStatModifierGroup(makeStats())
  
  controlModifiers = config.getParameter("controlModifiers") or {}
end

function update(dt)
  local duration = effect.duration()
  
  local r = 1
  
  if buildupTimer > 0 then
    buildupTimer = math.max(buildupTimer - dt / buildupTime)
    r = 1 - buildupTimer
    effect.setStatModifierGroup(groupId, makeStats(r))
  else
    local timer = duration / startDuration
    if timer <= restore then
      r = timer / restore
      effect.setStatModifierGroup(groupId, makeStats(r))
    elseif duration > lastDuration then
      effect.setStatModifierGroup(groupId, makeStats())
    end
  end
  
  local controls = {}
  for k,v in pairs(controlModifiers) do
    controls[k] = interp.sin(r, 1, v)
  end
  mcontroller.controlModifiers(controls)
  
  effect.setParentDirectives(string.format("fade=%s=%.1f", color, r * 0.6))
  
  animator.setSoundVolume("loop", interp.sin(r, 0, 1))
  
  lastDuration = duration
end

local resourceNames = {
  maxHealth = "health",
  maxEnergy = "energy"
}

function makeStats(r)
  r = r or 1
  local stats = {}
  
  for k,v in pairs(modifiers) do
    if resourceNames[k] and status.isResource(resourceNames[k]) then
      v = -math.floor(status.resourceMax(resourceNames[k]) * (1 - v))
    end
    
    local a = interp.sin(r, 0, v)
    if k ~= "powerMultiplier" then a = math.ceil(a) end
    
    stats[#stats+1] = {stat = k, amount = a}
  end
  
  return stats
end