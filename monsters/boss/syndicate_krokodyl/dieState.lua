--------------------------------------------------------------------------------
dieState = {}

function dieState.enterWith(params)
  if not params.die then return nil end

  return {}
end

function dieState.enteringState(stateData)
  triggerDeath()
  if not storage.dead then triggerDeath() end
  animator.stopAllSounds("idle")
  setActiveSkillName("fuckingdeadyouloser")
end

function triggerDeath()
  --Make it look dead
  storage.dead = true
  self.charging = false
  animator.setAnimationState("movement", "off")
  animator.setAnimationState("hull", "destroyed")
  updateDamageSources(nil)
  animator.setAnimationState("laser_cannon", "idle")
  monster.setAnimationParameter("chains", nil)
  
  --Unbossify it and stop it from taking damage
  monster.setDamageOnTouch(false)
  monster.setDamageBar("None")
  status.addPersistentEffect("neb_syndicate_krokodyl", "invulnerable")
	
  --Drop loot
  local dropPools = config.getParameter("dropPools", {})
  for _, pool in pairs(dropPools) do
    world.spawnTreasure(mcontroller.position(), pool, 1)
  end
  
  --Spawn some explosions
  explode(15)
  
  world.sendEntityMessage("exitDoor", "openDoor")
end

function dieState.update(dt, stateData)
  return false
end

function explode(count)
  local params = {}
  params.power = 0
  params.actionOnReap = {
    {
      action = "projectile",
      inheritDamageFactor = 0,
      type = "mechexplosion"
    }
  }
  for i = 1, count do
    local randAngle = math.random() * math.pi * 2
	  local randOffset = {math.random() * 9 - 4.5, math.random() * 4 - 2.5}
    local spawnPosition = vec2.add(mcontroller.position(), randOffset)
    local aimVector = {math.cos(randAngle), math.sin(randAngle)}
    
    params.timeToLive = math.random() * 3
    world.spawnProjectile("shockwavespawner", spawnPosition, entity.id(), aimVector, false, params)
  end
end
