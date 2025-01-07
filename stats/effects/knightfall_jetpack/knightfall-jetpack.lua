require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()
  self.flyingconfig = config.getParameter("flyingconfig", {})
  self.maxFallVelocity = config.getParameter("maxFallVelocity",-25)
  self.fallingSlowdownForce = config.getParameter("fallingSlowdownForce",100)
  self.flightEnergy = config.getParameter("flightEnergy",1) --How much energy is being used when flying
  self.fallingEnergy = config.getParameter("fallingEnergy",0.1) --How much energy is being used when falling
  self.engineOffset = config.getParameter("engineOffset",{-1.375, 0.05})
  self.engineOffsetRotationCorrection = config.getParameter("engineOffsetRotationCorrection",{0, 0.625})
  self.rotationLimiter = config.getParameter("rotationLimiter",50) --How much should the engine tilt
  self.chargeTimerB = config.getParameter("chargeTimer",1)
  self.chargedBoostSpeed = config.getParameter("chargedBoostSpeed",100)
  self.chargedBoost = config.getParameter("chargedBoost",true)
  self.projectileType = "knightfall_fuelcanisterexplosion"
  animator.resetTransformationGroup("engine")

  self.chargeTimer = self.chargeTimerB
end

--Main function
function update(dt)
  animator.resetTransformationGroup("engine")

  --Charged Boost
  if self.chargedBoost then
    --Charge boost timer
    if self.chargeboost then
      self.chargeTimer = math.max(0, self.chargeTimer - dt)
      world.debugText("Charge Timer: " .. self.chargeTimer, mcontroller.position(), "red")
      --If charged
      if self.chargeTimer <= 0 then
        self.charged = true
        animator.setParticleEmitterActive("exhaust1", true)
      end
    end

    --Charged boost trigger
    if mcontroller.crouching() and not self.chargeboost then
    self.engineOffset = vec2.add(self.engineOffset, {0, -0.75})
    self.chargeboost = true
    animator.playSound("chargedBoostCharge")
    elseif not mcontroller.crouching() and self.chargeboost then
    if self.charged then
      --When charged, do
      self.charged = false
      mcontroller.setYVelocity(self.chargedBoostSpeed)
      animator.burstParticleEmitter("boost")
      explode()
    end
    self.engineOffset = vec2.add(self.engineOffset, {0, 0.75})
    self.chargeboost = false
    self.chargeTimer = self.chargeTimerB
    end
  end

  --Initial posing
  if mcontroller.facingDirection() < 0 then
    animator.setGlobalTag("facingDirection", "flipx") 
  else
    animator.setGlobalTag("facingDirection", "")
  end
  self.flipEngineOffset = {((self.engineOffset[1])*mcontroller.facingDirection()),self.engineOffset[2]}

  --Apply all offsets to the engine
  animator.translateTransformationGroup("engine", self.flipEngineOffset)

  --Flying state trigger
  if flyReady() and jumpOrFall() and not self.able then
    self.able = true
    animationOn()
  elseif not flyReady() and self.able then
    self.able = false
    animationOff()
  end

  --zeroG state trigger
  if inZeroG() and not self.zeroG then
    self.zeroG = true
    animationOn()
  elseif not inZeroG() and self.zeroG then
    self.zeroG = false
    animationOff()
  end

  if self.able then
    --Thruster rotation
    local angle = -math.atan(mcontroller.xVelocity(), math.max(self.rotationLimiter,mcontroller.yVelocity()))
    world.debugText("Angle " .. angle, mcontroller.position(), "red")
    animator.rotateTransformationGroup("engine",angle,vec2.add(self.flipEngineOffset,self.engineOffsetRotationCorrection))
    --Applying flying config
    mcontroller.controlParameters(self.flyingconfig)
    mcontroller.controlParameters({gravityMultiplier = 0.75})
    --Flying up
    if mcontroller.jumping() then
      status.overConsumeResource("energy", self.flightEnergy)
    --Falling
    elseif mcontroller.falling() then
      status.overConsumeResource("energy", self.fallingEnergy)
      --Slow down when falling
      if mcontroller.yVelocity() < self.maxFallVelocity then
        mcontroller.controlApproachYVelocity(self.maxFallVelocity, self.fallingSlowdownForce)
      end
    end
--else
--    Something that would happen if jetpack isn't able to fly.
  end

  if self.zeroG then
    --Experimental method of rotation towards the acceleration vector. Currently is kinda wonky, so is replace by the standart velocity targeting.
    --Thruster rotation
    local vel = mcontroller.velocity()
    local accel = vec2.div(vec2.sub(vel, self.lastVel or vel), dt)
    self.lastVel = vel
    -- local angle = vec2.angle(accel)
    world.debugText("Accel " .. vec2.mag(accel), vec2.add(mcontroller.position(),{0, -2}), "green")
    local angle = -math.atan(mcontroller.xVelocity(), mcontroller.yVelocity())
    world.debugText("Angle " .. util.toDegrees(angle), mcontroller.position(), "red")
    
    -- local resultant = util.lerp(0.1, self.previousAngle or angle, angle)
    -- self.previousAngle = resultant

    if not self.zeroGaccel and not vec2.eq(accel, {0, 0}) then
      self.zeroGaccel = true
      animationOn()
    elseif self.zeroGaccel and vec2.eq(accel, {0, 0}) then
      self.zeroGaccel = false
      animationOff()
    end

    -- --Capping acceleration to the max value
    --   if accel[1] > 0 then mcontroller.controlAcceleration({1, 0})
    --   elseif accel[1] < 0 then mcontroller.controlAcceleration({-1, 0})
    --   end
      
    --   if accel[2] > 0 then mcontroller.controlAcceleration({0, 1})
    --   elseif accel[2] < 0 then mcontroller.controlAcceleration({0, -1})
    --   end

    if self.zeroGaccel then
      animator.rotateTransformationGroup("engine",angle,vec2.add(self.flipEngineOffset,self.engineOffsetRotationCorrection))
      status.overConsumeResource("energy", self.flightEnergy)
      if not mcontroller.isColliding() then
        mcontroller.controlParameters({mass = vec2.mag(accel)/75})
      end
    end

    --Applying flying config
    world.debugText("Mass " .. mcontroller.mass(), vec2.add(mcontroller.position(),{0, -6}), "green")
    mcontroller.controlModifiers({speedModifier = 20})
  end
end

function animationOn()
  animator.setLightActive("engine", true)
  animator.playSound("thrust")
  animator.playSound("loop",-1)
  animator.setAnimationState("engine", "active")
  animator.setParticleEmitterActive("exhaust", true)
  animator.setParticleEmitterActive("exhaust1", true)
end

function animationOff()
  animator.setLightActive("engine", false)
  animator.playSound("off")
  animator.stopAllSounds("loop")
  animator.setAnimationState("engine", "off")
  animator.setParticleEmitterActive("exhaust", false)
  animator.setParticleEmitterActive("exhaust1", false)
end

function explode()
  local parameters = {power = 100}
  animator.playSound("chargedBoost")
  world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(),{4, 0}), effect.sourceEntity(), {0, 0}, false, parameters)
  world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(),{-4, 0}), effect.sourceEntity(), {0, 0}, false, parameters)
  world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(),{8, 0}), effect.sourceEntity(), {0, 0}, false, parameters)
  world.spawnProjectile(self.projectileType, vec2.add(mcontroller.position(),{-8, 0}), effect.sourceEntity(), {0, 0}, false, parameters)
  world.spawnProjectile(self.projectileType, mcontroller.position(), effect.sourceEntity(), {0, 0}, false, parameters)
end
--Detect if player is not on ground, not in water and has enough energy.
function flyReady()
  return not mcontroller.liquidMovement()
    and world.gravity(mcontroller.position()) > 0.1
    and not mcontroller.groundMovement()
    and not status.resourceLocked("energy")
end

function inZeroG()
  return world.gravity(mcontroller.position()) < 0.1
    and not mcontroller.groundMovement()
    and not status.resourceLocked("energy")
end

function jumpOrFall()
  return mcontroller.jumping() or mcontroller.falling()
end

function uninit()
  animationOff()
end

function onExpire()
  animationOff()
end