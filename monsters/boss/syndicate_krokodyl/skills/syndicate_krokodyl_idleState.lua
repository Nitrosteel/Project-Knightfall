--Not really an attack, just some idle time between attacks
syndicate_krokodyl_idleState = {}

function syndicate_krokodyl_idleState.enter()
  if not hasTarget() then return nil end

  return {
    timer = 0,
    idleTime = config.getParameter("syndicate_krokodyl_idleState.idleTime", 2.5)
  }
end

function syndicate_krokodyl_idleState.enteringState(stateData)
  playSound("idle", -1)
  setActiveSkillName("syndicate_krokodyl_idleState")
end

function syndicate_krokodyl_idleState.update(dt, stateData)
  if targetIsBehind() then return true end
  
  stateData.timer = stateData.timer + dt

  if stateData.timer > stateData.idleTime then
    return true
  end
end

function syndicate_krokodyl_idleState.leavingState(stateData)
  setActiveSkillName()
end