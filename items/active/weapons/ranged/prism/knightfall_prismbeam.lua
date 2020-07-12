require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"


--[[-- 
  * multibeam.lua
  *
  * BeamFire-like script that provides the ability for the beam to bounce against enemies, optionally
  * spawn projectiles at the entities hit, and optionally spawn a projectile on tile collision.
  * Part of the script is from beamfire.lua in assets.
  *
  * Created by Lyrthras#7199 on 06/25/20
  * v1.1 [06/26/20] - added json param mappings
--]]--

--[[--
  === JSON fields ( * = required ) ===
  * fireTime          - float: rate of fire per second; should be > beamPresenceTime to avoid damage multiple times in a single shot
  * beamPresenceTime  - float: how long (seconds) the beam should exist (including the damage source)
  * beamLength        - float: maximum beam length (the total length of all produced beams while not colliding against a tile)
  - mode              - string:[def "refract"] or "reflect". Whether the beam should reflect from entities, or refract through them. Invalid mode becomes default.
  - angleMode         - string:[def "entity"] or "beam" - whether the refracted/reflected beam direction is based on the beam or just the y-axis (entity)
  - angleVariation    - float: [def 0] a range (in degrees) for the possible random direction the next beam could take. 90 for a right angle cone. 0 to disable randomness
  - energyPerShot     - float: [def 0] energy consumed per shot, overConsume is enabled (will still consume energy if remaining energy < energyPerShot). Alias: energyUsage
  - maxBounces        - int:   [def 1] maximum entity bounces before the beam wouldn't bounce from the next entity anymore
  
  - entityHitProjectile   - projectile: Projectile to spawn when the beam hits an entity ^
  - tileHitProjectile     - projectile: Projectile to spawn when the beam collides against tiles ^

  - beamTransitionTime    - float: [def 0] If the beam is animated, the amount of time to complete the beam animation. 0 to disable (use the last frame instantly)
  - beamTransitionFrames  - int:   [def 1] If the beam is animated, the count of frames the sprite has. (Default only uses the first frame)

  Note ^ : projectile - contains `type` (string, projectile id) and `parameters` (table, projectile parameters) fields
  Note 2 : baseDps or damageConfig.baseDamage should be added (either of the two)
--]]--

MultiBeam = WeaponAbility:new()

function MultiBeam:init()
  -- weapon json params (assues interchangeability)
  if self.damageConfig.baseDamage then
    self.baseDps = self.damageConfig.baseDamage / self.fireTime
  else
    self.damageConfig.baseDamage = self.baseDps * self.fireTime
  end

  if self.energyPerShot then self.energyUsage = self.energyPerShot 
  elseif self.energyUsage then self.energyPerShot = self.energyUsage end

  self.weapon:setStance(self.stances.idle)

  math.randomseed(os.time())
  math.random()

  self.beams = jarray()
  self.damageSources = {}

  self.cooldownTimer = 0
  self.transitionTimer = 0

  self.weapon.onLeaveAbility = function()
    self:reset()
    self.weapon:setStance(self.stances.idle)
  end
end

function MultiBeam:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer    = math.max(self.cooldownTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") 
    and status.overConsumeResource("energy", (self.energyPerShot or 0)) then

    self.transitionTimer = 0
    self:setState(self.fire)
  end

  if self.weapon.currentState == self.fire then
    self.transitionTimer = math.min(self.transitionTimer + self.dt, self.beamTransitionTime)
  else 
    animator.setLightActive("muzzleFlash", false)
  end

  self:drawBeams()
end

function MultiBeam:fire()
  self.weapon:setStance(self.stances.fire)

  self:muzzleFlash()
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)

  self:raytrace(self:firePosition(), self:aimVector(0), self.beamLength, self.maxBounces or 1, {},
    -- onCollide --
    function(collisionType, position)
      local projectile
      if collisionType == "creature" then
        projectile = self.entityHitProjectile
      elseif collisionType == "block" then
        projectile = self.tileHitProjectile
      else return end

      if not projectile.type then return end

      local params = {
        damageTeam = world.entityDamageTeam(activeItem.ownerEntityId())
      }
      util.mergeTable(params, projectile.parameters or {})

      world.spawnProjectile(
        projectile.type,
        position,
        activeItem.ownerEntityId(),
        {math.random(-1,1)/3, -0.2},
        false,
        params
      )
    end)

  self:applyDamageSources()

  self.cooldownTimer = self.fireTime
  util.wait(self.beamPresenceTime, function() end)

  self:setState(self.cooldown)
  self:reset()
  animator.playSound("fireEnd")
end

--
function MultiBeam:raytrace(beamStart, towards, beamLength, bouncesLeft, visitedCreatures, onCollide)
  local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(towards), beamLength))

  local blockCollPoint = world.lineCollision(beamStart, beamEnd)
  local collidingCreature = self:findTargetEntity(beamStart, beamEnd, visitedCreatures)

  local collidePoint 
  local collideType
  if blockCollPoint and collidingCreature then
    local monsterCollPoint = world.entityPosition(collidingCreature)

    if (world.magnitude(beamStart, blockCollPoint) < world.magnitude(beamStart, monsterCollPoint)) then   -- blocked by tile
      collidePoint = blockCollPoint
      collideType  = "block"
    else                                -- monster hit
      collidePoint = monsterCollPoint 
      collideType  = "creature"
      table.insert(visitedCreatures, collidingCreature)
    end
  else
    if blockCollPoint then
      collidePoint = blockCollPoint
      collideType  = "block"
    elseif collidingCreature then
      collidePoint = world.entityPosition(collidingCreature)
      collideType  = "creature"
      table.insert(visitedCreatures, collidingCreature)
    end
  end

  beamEnd = collidePoint or beamEnd

  local damageLine = {        -- relative position from player
    world.distance(beamStart, mcontroller.position()),
    world.distance(beamEnd, mcontroller.position())
  }
  local damageSource = {
    line = damageLine, 
    damage = self.damageConfig.baseDamage,
    knockback = self.damageConfig.knockback,
    trackSourceEntity = false,
    team = world.entityDamageTeam(activeItem.ownerEntityId()),
    damageRepeatTimeout = self.fireTime,
    damageSourceKind = self.damageConfig.damageSourceKind or "default",
    statusEffects = self.damageConfig.statusEffects or {},
    damageRepeatGroup = activeItem.ownerEntityId() .. config.getParameter("itemName")
  }

  self:addDamageSource(damageSource)
  self:addBeam(beamStart, beamEnd, collidePoint)
  if onCollide then onCollide(collideType, collidePoint) end

  if (bouncesLeft == nil or bouncesLeft <= 0) then return end

  local remainingDistance = beamLength - world.magnitude(beamStart, beamEnd)
  if collideType == "creature" and remainingDistance > 0 then

    -- determine the next beam's direction
    local direction
    if self.angleMode == "beam" then
      if self.mode == "reflect" then
        direction = vec2.mul(vec2.sub(damageLine[2], damageLine[1]), {-1, 1})  -- mirror beam along the Y axis. TODO, mirror along X if 45 deg downward
      else          -- refract
        direction = vec2.mul(vec2.sub(damageLine[2], damageLine[1]), {1, -1})  -- mirror beam along X axis. TODO, mirror along diagonal if 45 deg
      end
    else          -- reference to y axis
      if damageLine[1][1] < damageLine[2][1] then     -- if beamStart.x less than beamEnd.x, source beam was going to the right
        direction = (self.mode == "reflect" and {-1,0} or {1,0})
      else        -- source beam was going to the left
        direction = (self.mode == "reflect" and {1,0} or {-1,0})
      end
    end

    -- apply randomness
    local rotation = self.angleVariation and util.clamp(sb.nrand(self.angleVariation/(2*2), 0), -self.angleVariation*math.sqrt(2), self.angleVariation*math.sqrt(2)) or 0    -- normalized, squeezed 2x
    direction = vec2.rotate(direction, util.toRadians(rotation))
    
    self:raytrace(
      beamEnd, 
      direction,  
      remainingDistance,
      bouncesLeft - 1,
      copy(visitedCreatures),
      onCollide
    )
  end
end

function MultiBeam:addDamageSource(damageSource)
  table.insert(self.damageSources, damageSource)
end

function MultiBeam:applyDamageSources()
  activeItem.setDamageSources(self.damageSources)
end

function MultiBeam:resetDamageSources()
  self.damageSources = {}
  activeItem.setDamageSources({})
end

function MultiBeam:addBeam(startPos, endPos, didCollide)
  local newChain = copy(self.chain)

  newChain.startPosition = startPos
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos
  newChain.currentFrame = -1

  if didCollide then
    newChain.endSegmentImage = nil
  end

  table.insert(self.beams, newChain)
end

function MultiBeam:drawBeams()
  local currentFrame = self:beamFrame()
  local baseChain = copy(self.chain)
  
  for _,newChain in ipairs(self.beams) do
    if newChain.currentFrame ~= currentFrame then       -- Performance: don't change if it's already the same frame
      if newChain.startSegmentImage then
        newChain.startSegmentImage = baseChain.startSegmentImage:gsub("<beamFrame>", currentFrame)
      end
      newChain.segmentImage = baseChain.segmentImage:gsub("<beamFrame>", currentFrame)
      if newChain.endSegmentImage then
        newChain.endSegmentImage = baseChain.endSegmentImage:gsub("<beamFrame>", currentFrame)
      end
      newChain.currentFrame = currentFrame
    end
  end

  activeItem.setScriptedAnimationParameter("chains", self.beams)
end

function MultiBeam:resetBeams()
  self.beams = jarray()
  activeItem.setScriptedAnimationParameter("chains", {})
end

function MultiBeam:beamFrame()
  local transitionTime = (self.beamTransitionTime or 0) + 0.004    -- prevent div by zero
  local targetFrame = math.floor(self.transitionTimer * self.beamTransitionFrames / transitionTime + 1.25)
  return math.max(1, math.min(self.beamTransitionFrames, targetFrame))
end

function MultiBeam:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

---------------------------------

-- Return the EntityId of the nearest valid target hit by a ray between the
-- two given positions.
-- Added: ignoreEntities - continues searching if entity is within table
-- From evileye.lua
function MultiBeam:findTargetEntity(startPosition, endPosition, ignoredEntities)
  local entities = world.entityQuery(startPosition, endPosition, {
      line = {startPosition, endPosition},
      order = "nearest",
      includedTypes = {"creature"}
    })

  for _,entityId in pairs(entities) do
    if world.entityCanDamage(activeItem.ownerEntityId(), entityId) 
        and not contains(ignoredEntities, entityId) then
      return entityId
    end
  end
  return nil
end

---------------------------------

function MultiBeam:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function() 
    if self.transitionTimer > 0 then
      self.transitionTimer = math.max(0, self.transitionTimer - self.dt)
      if self.transitionTimer == 0 then self:resetBeams() end
    end
  end)
end

function MultiBeam:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function MultiBeam:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function MultiBeam:uninit()
  self:reset()
end

function MultiBeam:reset()
  self.weapon:setDamage()
  self:resetDamageSources()
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
end