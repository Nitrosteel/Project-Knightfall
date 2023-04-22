require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"


--[[-- 
  * knightfall_prismbeam.lua
  * Class: MultiBeam
  *
  * BeamFire-like script that provides the ability for the beam to bounce against enemies, optionally
  * spawn projectiles at the entities hit, and optionally spawn a projectile on tile collision.
  * Part of the script is from beamfire.lua in assets.
  *
  * NOTES:
  * - Use "MultiBeamAlt" for the ability class if used as an alt ability instead
  *
  * Created by Lyrthras#7199 (sub) on 06/25/20
  * v1.1 [06/26/20] - added json param mappings
  * v1.2 [06/27/20] - small fixes; use the default json field name for energy usage
  * v1.4 [07/30/20] - fixes, code and docs cleanup; added "pierce" mode, use
  *                   lightning render if "lightningConfig" is specified in JSON.
  *                   Also included damageConfig.damageRepeatTimeout to allow for
  *                   repeated damage in a single shot.
  * v1.4a [08/02/20]- Added ability to specify custom muzzle offset, and disable flash
  * v1.4b [03/17/22]- beam can extend when bounced on enemies with hitExtendPercent
--]]--

--[[--
  === JSON fields ( * = required ) ===
  [ Weapon configs ]
  * fireTime          - float: rate of fire per second; should be > beamPresenceTime to avoid multiple source beams existing
  * beamPresenceTime  - float: how long (seconds) the beam should exist (including the damage source)
  * beamLength        - float: maximum beam length (the total length of all produced beams while not colliding against a tile)
  * baseDps           - float: the base DPS of the weapon (damageConfig.baseDamage has priority, though) ^
  * damageConfig      - DamageConfig: damage config of the beam itself (not the projectiles)
  * stances           - Stances: the weapon's stances
  - energyUsage       - float: [def 0] energy consumed per shot, overConsume is enabled (will still consume energy if remaining energy < energyUsage).
  - mode              - string:[def "refract"], "reflect", or "pierce". Whether the beam should reflect from entities, refract through them, or ignore them (pierce).
  ( Fields only for "refract" or "reflect" modes: )
  - angleMode        - string:[def "entity"] or "beam" - whether the refracted/reflected beam direction is based on the beam or just the y-axis (entity)
  - angleVariation   - float: [def 0] a range (in degrees) for the possible random direction the next beam could take. 90 for a right angle cone. 0 to disable randomness
  - maxBounces       - int:   [def 1] maximum entity bounces before the beam wouldn't bounce from the next entity anymore
  - hitExtendPercent - float: [def 0.25] bouncing on entities extends beam by this percent of beamLength

  [ Projectile configs ]
  - entityHitProjectile   - projectile: Projectile to spawn when the beam hits an entity ^^
  - tileHitProjectile     - projectile: Projectile to spawn when the beam collides against tiles ^^

  [ Beam configs ]
  ( if only lightningConfig is NOT present: )
  * chain                 - Chain: the beam chain definition, look at beamfire weapon activeitems for uses
  - beamTransitionTime    - float: [def 0] If the beam is animated, the amount of time to complete the beam animation. 0 to disable (use the last frame instantly)
  - beamTransitionFrames  - int:   [def 1] If the beam is animated, the count of frames the sprite has. (Default only uses the first frame)
  ( for lightning render: )
  * lightningConfig       - LightningConfig: check the guidedbolt weaponability for a sample (in /items/active/weapons/staff/abilities/guidedbolt/)
  - lightningStartColor   - Color: [def {255,255,255,200}] an [R,G,B,A] table of the lightning's initial color
  - lightningEndColor     - Color: [def {155,155,255,  0}] the start color fades to this color before disappearing

  Note ^  : baseDps is baseDamage / fireTime. To specify baseDamage, use self.damageConfig.baseDamage instead
  Note ^^ : projectile - contains `type` (string, projectile id) and `parameters` (table, projectile parameters) fields
--]]--

MultiBeam = WeaponAbility:new()

-- Alt MultiBeam class metatable magic.
MultiBeamAlt = {isAltAbility = true, __index = MultiBeam}
setmetatable(MultiBeamAlt, MultiBeamAlt)

function MultiBeam:init()
  self.weapon:setStance(self.stances.idle)

  math.randomseed(os.time())
  math.random()

  -- weapon json params (assures interchangeability)
  if self.damageConfig.baseDamage then
    self.baseDps = self.damageConfig.baseDamage / self.fireTime
  else
    self.damageConfig.baseDamage = self.baseDps * self.fireTime
  end

  self.isLightning = (type(self.lightningConfig) == "table")
  self.lightningStartColor  = self.lightningStartColor or {255,255,255,200}
  self.lightningEndColor    = self.lightningEndColor   or {155,155,255,  0}

  self.beams = jarray()
  self.damageSources = {}

  self.cooldownTimer = 0
  self.transitionTimer = 0
	
	self.hitExtendPercent = self.hitExtendPercent or 0.25

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
    and (self.fireMode == (self.isAltAbility and "alt" or "primary"))
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") 
    and status.overConsumeResource("energy", (self.energyUsage or 0)) then

    self.transitionTimer = 0
    self:setState(self.fire)
  end

  if not self.isLightning and self.weapon.currentState == self.fire then
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

  self:raytrace(self:firePosition(), self:aimVector(0), self.beamSegmentLength, self.beamLength, self.maxBounces or 1, {},
    -- onCollide --
    function(collisionType, position)
      local projectile
      if collisionType == "creature" then
        projectile = self.entityHitProjectile
      elseif collisionType == "block" then
        projectile = self.tileHitProjectile
      else return end

      if not projectile or not projectile.type then return end

      local params = {
        damageTeam = world.entityDamageTeam(activeItem.ownerEntityId())
      }
      util.mergeTable(params, projectile.parameters or {})

      -- small amount of random so projectile isn't at immediate entity center
      local randomVec = {math.random(-1,1) / 4, math.random(-1,1) / 4}
      world.spawnProjectile(
        projectile.type,
        vec2.add(position, randomVec),
        activeItem.ownerEntityId(),
        randomVec,
        false,
        params
      )
    end)

  self:applyDamageSources()

  self.cooldownTimer = self.fireTime

  -- draw beams for lightning render if isLightning
  if self.isLightning then
    self.transitionTimer = self.beamPresenceTime
    activeItem.setScriptedAnimationParameter("lightningSeed", math.floor((os.time() + (os.clock() % 1)) * 1000))
  end
  util.wait(self.beamPresenceTime, function(dt) self:drawBeams(dt) end)

  self:setState(self.cooldown)
  -- unset because vanilla lightning.lua will keep using the same seed
  -- and set it as the global random seed >:(
  activeItem.setScriptedAnimationParameter("lightningSeed", nil)
  self:reset()
  animator.playSound("fireEnd")
end

function MultiBeam:raytrace(beamStart, towards, beamSegLength, beamLength, bouncesLeft, visitedCreatures, onCollide)
  local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(towards), math.min(beamSegLength or beamLength, beamLength)))
  local piercing = (self.mode == "pierce")

  local blockCollPoint = world.lineCollision(beamStart, beamEnd)
  local creatureCollPoint
  local collidingCreature

  local targets = world.entityLineQuery(beamStart, beamEnd, {
		withoutEntityId = activeItem.ownerEntityId(),
		includedTypes = {"creature"},
		order = "nearest"
	  })
	  --Set the default distance to nearest target to max search distance
	  local nearestTargetDistance = beamLength
	  for _, target in ipairs(targets) do
		--Make sure we can damage the targeted entity
		if world.entityCanDamage(activeItem.ownerEntityId(), target) then
		  local targetPosition = world.entityPosition(target)
		  --Make sure we have line of sight on this entity
		  if not world.lineCollision(beamStart, targetPosition) 
        and not contains(visitedCreatures, target) then
        
			  local targetDistance = world.magnitude(beamStart, targetPosition)
			  --If the target currently being processed is closer than the nearest target found so far, make this target the nearest target
			  if targetDistance < nearestTargetDistance then
			    nearestTargetDistance = targetDistance
			    local beamDirection = vec2.rotate({1, 0}, self.weapon.aimAngle)
			    beamDirection[1] = beamDirection[1] * mcontroller.facingDirection()
			    local beamVector = vec2.mul(beamDirection, nearestTargetDistance)
			    creatureCollPoint = vec2.add(beamStart, beamVector)
          collidingCreature = target
			  end
		  end
		end
	end

  local collidePoint
  local collideType
  if blockCollPoint and (creatureCollPoint and (world.magnitude(blockCollPoint, creatureCollPoint) < 0) or true) and not creatureCollPoint then
    collidePoint = blockCollPoint
    collideType = "block"
  elseif collidingCreature then
    collidePoint = creatureCollPoint
    collideType = "creature"
    table.insert(visitedCreatures, collidingCreature)
  end
  beamEnd = collidePoint or beamEnd

  local damageSource = {
    line = { beamStart, beamEnd },
    damage = self.damageConfig.baseDamage,
    knockback = self.damageConfig.knockback,
    trackSourceEntity = false,
    sourceEntity = activeItem.ownerEntityId(),
    team = activeItem.ownerTeam(),
    damageRepeatTimeout = self.damageConfig.damageRepeatTimeout or self.fireTime,
    damageSourceKind = self.damageConfig.damageSourceKind or "default",
    statusEffects = self.damageConfig.statusEffects or {},
    damageRepeatGroup = activeItem.ownerEntityId() .. config.getParameter("itemName")
  }

  --world.debugLine(beamStart, beamEnd, {255,255,255,255})
  self:addDamageSource(damageSource)
  self:addBeam(beamStart, beamEnd, collidePoint)
  if onCollide then onCollide(collideType, collidePoint) end

  local remainingDistance = beamLength - world.magnitude(beamStart, beamEnd)
  if bouncesLeft ~= nil
      and bouncesLeft > 0
      and collideType == "creature"
      and remainingDistance > 0 then

    -- determine the next beam's direction
    local damageLine = {        -- convert to relative position from player
      world.distance(beamStart, mcontroller.position()),
      world.distance(beamEnd, mcontroller.position())
    }
    local direction
    if self.angleMode == "beam" then
      if self.mode == "reflect" then
        direction = vec2.mul(vec2.sub(damageLine[2], damageLine[1]), {-1, 1})  -- mirror beam along the Y axis.
      else          -- refract
        direction = vec2.mul(vec2.sub(damageLine[2], damageLine[1]), {1, -1})  -- mirror beam along X axis.
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
        beamSegLength,
        remainingDistance + (self.beamLength * self.hitExtendPercent),
        bouncesLeft - 1,
        copy(visitedCreatures),
        onCollide
    )
  elseif collideType == nil and remainingDistance > 0 then
    self:raytrace(
        beamEnd,
        towards,
        beamSegLength,
        remainingDistance,
        bouncesLeft,
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
  if self.isLightning then
    local newSegment = copy(self.lightningConfig)

    newSegment.worldStartPosition = startPos
    newSegment.worldEndPosition = endPos
    newSegment.displacement = vec2.mag(vec2.sub(startPos, endPos)) / 5
    table.insert(self.beams, newSegment)
    table.insert(self.beams, newSegment)
  else
    local newChain = copy(self.chain)

    newChain.startPosition = startPos
    newChain.startOffset = self.muzzleOffset or self.weapon.muzzleOffset
    newChain.endPosition = endPos
    newChain.currentFrame = -1

    if didCollide then
      newChain.endSegmentImage = nil
    end

    table.insert(self.beams, newChain)
  end
end

function MultiBeam:drawBeams(dt)
  if dt and self.isLightning then
    -- from guidedbolt.lua
    local colorFactor = 1 - (self.transitionTimer / self.beamPresenceTime)
    local lightningColor = {
      util.lerp(colorFactor, self.lightningStartColor[1], self.lightningEndColor[1]),
      util.lerp(colorFactor, self.lightningStartColor[2], self.lightningEndColor[2]),
      util.lerp(colorFactor, self.lightningStartColor[3], self.lightningEndColor[3]),
      util.lerp(colorFactor, self.lightningStartColor[4], self.lightningEndColor[4])
    }
    for i, bolt in ipairs(self.beams) do
      self.beams[i].color = lightningColor
    end

    self.transitionTimer = math.max(0, self.transitionTimer - dt)

    activeItem.setScriptedAnimationParameter("lightning", self.beams)
  elseif not self.isLightning then
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
  
	  --Optionally hueshift the chain beam
	  if self.hueShiftFrequency then
		local hueShift = "?hueshift=" .. (self.transitionTimer / self.beamPresenceTime * math.random(0, 360)) % 360 
		newChain.segmentImage = newChain.segmentImage:gsub("<hueShift>", hueShift)
		if newChain.startSegmentImage then
		  newChain.startSegmentImage = newChain.startSegmentImage:gsub("<hueShift>", hueShift)
		end
		if newChain.endSegmentImage then
		  newChain.endSegmentImage = newChain.endSegmentImage:gsub("<hueShift>", hueShift)
		end
	  end
    end

    activeItem.setScriptedAnimationParameter("chains", self.beams)
  end
end

function MultiBeam:resetBeams()
  self.beams = jarray()
  activeItem.setScriptedAnimationParameter("chains", {})
  activeItem.setScriptedAnimationParameter("lightning", {})
end

function MultiBeam:beamFrame()
  local transitionTime = (self.beamTransitionTime or 0) + 0.004    -- prevent div by zero
  local targetFrame = math.floor(self.transitionTimer * self.beamTransitionFrames / transitionTime + 1.25)
  return math.max(1, math.min(self.beamTransitionFrames, targetFrame))
end

function MultiBeam:muzzleFlash()
  if not self.disableMuzzleFlash then
    animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    animator.burstParticleEmitter("muzzleFlash")
    animator.setLightActive("muzzleFlash", true)
    animator.setAnimationState("firing", "fire")
  end
  animator.playSound("fire")
end

---------------------------------

function MultiBeam:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local done = false
  util.wait(self.stances.cooldown.duration, function()
    if done then return end
    self.transitionTimer = math.max(0, self.transitionTimer - self.dt)
    if self.transitionTimer == 0 then
      self:resetBeams()
      done = true
    end
  end)
end

function MultiBeam:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.muzzleOffset or self.weapon.muzzleOffset))
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
  animator.stopAllSounds("fireLoop")
end