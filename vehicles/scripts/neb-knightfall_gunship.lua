require "/scripts/vec2.lua"
require "/scripts/util.lua"

--Original version created by Mikenyes/Mikenno/Mylie

--Reworked and updated by Nebulox
--HUGE WIP

--Initialise variables and information
function init()
  --ROTATION AND ANGLES
  --The factor to reach the base angle
  self.equaliseFactor = config.getParameter("equaliseFactor", 0)
  --Factor of rotation to reach the actual angle we need to be at
  self.angleApproachFactor = config.getParameter("angleApproachFactor", 0)
  --Max angle offset
  self.maxAngle = config.getParameter("maxAngle", 30) * math.pi / 180
  --Determine whether we should constantly check the angle
  self.continuousAngleCheck = config.getParameter("continuousAngleCheck", true)
  
  --Determine whether the rotation should be based on velocity
  self.baseRotationOnVelocity = config.getParameter("baseRotationOnVelocity", true)
  --Factor to rotate to target angle
  self.velocityRotationApproachFactor = config.getParameter("velocityRotationApproachFactor", 0.01)
  
  
  --FLYING
  --Target velocities to reach
  self.targetVelocity = config.getParameter("targetVelocity", {50, 50})
  --Control forces to reach target velocity
  self.velocityControlForces = config.getParameter("velocityControlForces", {
    horizontal = 250,
    upward = 220,
    downward = 250
  })
  
  --PARKING
  self.canFly = config.getParameter("canFly")
  self.canLaunch = config.getParameter("canLaunch")
  
  --LAUNCHING
  self.launchVelocity = config.getParameter("launchVelocity")
  self.launchTimeout = config.getParameter("launchTimeout")
  
  --Search distance until giving up on finding the ground
  self.groundSearchMagnitude = config.getParameter("groundSearchMagnitude", 6)
  self.nearGroundDistance = config.getParameter("nearGroundDistance")
  
  --HOVERING
  self.hoverToggle = config.getParameter("hoverToggle")
  self.hoverToggleControlForce = config.getParameter("hoverToggleControlForce")
  
  self.hoverTargetDistance = config.getParameter("hoverTargetDistance", 5)
  self.hoverVelocityFactor = config.getParameter("hoverVelocityFactor", 0)
  self.hoverControlForce = config.getParameter("hoverControlForce", 4)
  
  --HEADLIGHT
  self.primaryHeadlight = config.getParameter("primaryHeadlight")
  
  --SPRING POSITIONS
  self.backSpringPositions = config.getParameter("backSpringPositions")
  self.frontSpringPositions = config.getParameter("frontSpringPositions")
  self.bodySpringPositions = config.getParameter("bodySpringPositions")
  
  --MOVEMENT SETTINGS
  self.movementSettings = config.getParameter("movementSettings")
  self.occupiedMovementSettings = config.getParameter("occupiedMovementSettings")
  self.zeroGMovementSettings = config.getParameter("zeroGMovementSettings")
  
  --STATS
  self.stats = config.getParameter("stats", {})
  
  --PARTICLES AND DAMAGED STATE
  self.smokeThreshold = config.getParameter("smokeThreshold")
  self.maxSmokeRate = config.getParameter("maxSmokeRate")
  self.fireThreshold = config.getParameter("fireThreshold")
  self.maxFireRate = config.getParameter("maxFireRate")

  self.onFireThreshold =  config.getParameter("onFireThreshold")
  self.damagePerSecondWhenOnFire =  config.getParameter("damagePerSecondWhenOnFire")

  self.engineDamageSoundThreshold =  config.getParameter("engineDamageSoundThreshold")
  self.intermittentDamageSoundThreshold = config.getParameter("intermittentDamageSoundThreshold")

  self.damageSoundInterval = config.getParameter("damageSoundInterval", {1, 2})
  
--UNTOUCHED
  self.minDamageCollisionAccel = config.getParameter("minDamageCollisionAccel")
  self.minNotificationCollisionAccel = config.getParameter("minNotificationCollisionAccel")
  self.terrainCollisionDamage = config.getParameter("terrainCollisionDamage")
  self.materialKind = config.getParameter("materialKind")
  self.terrainCollisionDamageSourceKind = config.getParameter("terrainCollisionDamageSourceKind")
  self.accelerationTrackingCount = config.getParameter("accelerationTrackingCount")

  self.damageStateNames = config.getParameter("damageStateNames")

  self.engineIdlePitch = config.getParameter("engineIdlePitch")
  self.engineRevPitch = config.getParameter("engineRevPitch")
  self.engineIdleVolume = config.getParameter("engineIdleVolume")
  self.engineRevVolume = config.getParameter("engineRevVolume")

  self.rearThrusterParticles = config.getParameter("rearThrusterParticles")
  self.ventralThrusterParticles = config.getParameter("ventralThrusterParticles")

  self.damageStatePassengerDances = config.getParameter("damageStatePassengerDances")
  self.damageStatePassengerEmotes = config.getParameter("damageStatePassengerEmotes")
  self.damageStateDriverEmotes = config.getParameter("damageStateDriverEmotes")

  self.mainStates = config.getParameter("mainStates")
  self.gunnery = config.getParameter("gunnery")
  self.thrusters = config.getParameter("thrusters",{})
  self.leveledGroups = config.getParameter("leveledGroups")
  self.primaryFireHorn = config.getParameter("primaryFireHorn")
  self.altFireHorn = config.getParameter("altFireHorn")
  self.special1ShipFlipLock = config.getParameter("special1ShipFlipLock")
  
  self.loopPlaying = nil;
  self.enginePitch = self.engineRevPitch;
  self.engineVolume = self.engineIdleVolume;

  self.driver = nil;
  self.facingDirection = config.getParameter("spawnFacingDirection",1)
  self.angle = 0
  self.spaceToggled = false
  animate()
  
  self.jumpTimer = 0
  self.engineRevTimer = 0.0
  self.revEngine = false
  self.damageSoundTimer = 0.0
  self.spin = 0
  self.cooldown = 0

  self.damageEmoteTimer = 0.0

  self.lastPosition = mcontroller.position()
  self.collisionDamageTrackingVelocities = {}
  self.collisionNotificationTrackingVelocities = {}
  self.selfDamageNotifications = {}

  --Initial state
  self.headlightCanToggle = true
  self.headlightsOn = false
  self.hornPlaying = false
  
  if self.primaryHeadlight or self.altFireHeadlight then
    animator.setAnimationState("headlights", "off")
  end

  --Controller information
  self.ownerKey = config.getParameter("ownerKey")
  vehicle.setPersistent(self.ownerKey)

  --Assume maxhealth
  if not (storage.health) then
    local startHealthFactor = config.getParameter("startHealthFactor")

    if (startHealthFactor == nil) then
       storage.health = self.stats.health
    else
       storage.health = math.min(startHealthFactor * self.stats.health, self.stats.health)
    end
    animator.setAnimationState("movement", "warpInPart1")
  end

  --Store functionality
  message.setHandler("store",
      function(_, _, ownerKey)
        if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil) then
          animator.setAnimationState("movement", "warpOutPart1")
          if self.primaryHeadlight or self.altFireHeadlight then
            switchHeadLights(1, 1, false)
          end
          animator.playSound("returnvehicle")
          return {storable = true, healthFactor = storage.health / self.stats.health}
        else
          return {storable = false, healthFactor = storage.health / self.stats.health}
        end
      end)
      
  --Termination functionality
  message.setHandler("terminateSelf",
      function(_,_)
        animator.setAnimationState("movement", "warpOutPart1")
        animator.playSound("returnvehicle")
      end)

  updateVisualEffects(storage.health, 0, false)
  
  if self.gunnery then
    for seat,arsenal in pairs(self.gunnery) do
      for arsenalTrigger,subarsenal in pairs(arsenal) do
        for gunName,gun in pairs(subarsenal) do
          gun.cooldown = gun.fireTime
          gun.activeCooldown = 0
          gun.weakActiveCooldown = 0
          gun.aimAngle = 0
          if gun.chain ~= nil then
            gun.chain.sourcePart = gunName
          end
        end
      end
    end
  end
end

function update()
  --If at world limit terminate vehicle
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    sb.logInfo("%s, vehicle at world limit!", config.getParameter("name", "Unknown Gunship"))
	return
  end

  --When invis terminate vehicle otherwise set functionality for active states
  if (animator.animationState("movement") == "invisible") then
    vehicle.destroy()
  elseif (animator.animationState("movement") == "warpInPart1" or animator.animationState("movement") == "warpOutPart1") then
    mcontroller.setPosition(self.lastPosition)
    mcontroller.setVelocity({0, 0})
  else
    local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")

    if (driverThisFrame ~= nil) then
      vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))
      if not self.special1ShipFlipLock then
        if world.distance(vehicle.aimPosition("drivingSeat"),mcontroller.position())[1] > 0 then
          self.facingDirection = 1
        else
          self.facingDirection = -1
        end
      end
    else
      vehicle.setDamageTeam({type = "passive"})
    end


	--Execute update functions
    local healthFactor = storage.health / self.stats.health
	
    move()
    controls()
    animate()
    updateDamage()
    updateDriveEffects(healthFactor, driverThisFrame)

    updatePassengers(healthFactor)

    if self.leveledGroups then
      for group, center in pairs(self.leveledGroups) do
        animator.resetTransformationGroup(group)
        animator.rotateTransformationGroup(group,-self.angle*self.facingDirection,center)
      end
    end

    self.driver = driverThisFrame
    if self.gunnery then
      for seat,arsenal in pairs(self.gunnery) do
        self.Special1Held = vehicle.controlHeld(seat,"Special1")
        self[seat.."Entity"] = vehicle.entityLoungingIn(seat)
        for arsenalTrigger,subarsenal in pairs(arsenal) do
          for gunName,gun in pairs(subarsenal) do
            gun.cooldown = math.max(gun.cooldown - script.updateDt(),0)
            if gun.firingType == "laser" then  
              gun.activeCooldown = math.max(gun.activeCooldown - script.updateDt(),0)
              if gun.activeCooldown == 0 then
                gun.weakActiveCooldown = math.max(gun.weakActiveCooldown - script.updateDt(),0)
                for i,damageSource in ipairs(gun.damageSourceList) do
                  vehicle.setDamageSourceEnabled(damageSource,false)
                end
                if not gun.weakChain or gun.weakActiveCooldown == 0 then
                  vehicle.setAnimationParameter("chains", {})
                else
                  local chains = {}
                  table.insert(chains, gun.weakChain)
                  vehicle.setAnimationParameter("chains", chains)
                end
              elseif self[seat.."Entity"] then
                local chains = {}
                table.insert(chains, gun.chain)
                vehicle.setAnimationParameter("chains", chains)
              end
            end
            if not (self.Special1Held and gun.special1AimLock) then
              if self[seat.."Entity"] then
                aimOffset = world.distance(vehicle.aimPosition(seat),vec2.add(mcontroller.position(),vec2.rotate(vec2.mul(gun.gunCenter,{self.facingDirection,1}),self.angle)))
                gun.aimAngle = math.atan(aimOffset[2],aimOffset[1]) - self.angle
              elseif gun.emptyAim then
                gun.aimAngle = self.facingDirection > 0 and gun.emptyAim/180*math.pi or util.wrapAngle(-gun.emptyAim/180*math.pi-math.pi)
              else
                gun.aimAngle = 0
              end
            end
            if gun.slavedTo then
              gun.aimAngle = subarsenal[gun.slavedTo].aimAngle or gun.aimAngle or 0
            elseif gun.aimMinMax then
              if self.facingDirection > 0 then
                gun.aimAngle = util.clamp(gun.aimAngle,(gun.aimMinMax[1]-self.angle)/180*math.pi,(gun.aimMinMax[2]-self.angle)/180*math.pi)
              else
                gun.aimAngle = util.clamp(util.wrapAngle(gun.aimAngle),util.wrapAngle(-math.pi-(gun.aimMinMax[2]-self.angle)/180*math.pi),util.wrapAngle(-math.pi-(gun.aimMinMax[1]-self.angle)/180*math.pi))
              end
            end
            if gun.slaves then
              for i,slave in ipairs(gun.slaves) do
                subarsenal[slave].aimAngle = gun.aimAngle
              end
            end
            if not gun.noGroup and not (gun.laserRotationLock and (gun.activeCooldown > 0 or gun.weakActiveCooldown > 0)) then
              animator.resetTransformationGroup(gun.gunName or gunName)
              animator.rotateTransformationGroup(gun.gunName or gunName,(gun.aimAngle-0.5*math.pi)*self.facingDirection+0.5*math.pi,gun.gunCenter)
            end
          end
        end
      end
    end
    if self.hoverToggled then
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[1]*math.pi/180
      end
    elseif ((vehicle.controlHeld("drivingSeat","left") and self.facingDirection == -1) or (vehicle.controlHeld("drivingSeat","right") and self.facingDirection == 1)) and vehicle.controlHeld("drivingSeat","up") then
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[2]*math.pi/180
      end
    elseif ((vehicle.controlHeld("drivingSeat","left") and self.facingDirection == -1) or (vehicle.controlHeld("drivingSeat","right")) and self.facingDirection == 1) then
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[3]*math.pi/180
      end
    elseif ((vehicle.controlHeld("drivingSeat","left") and self.facingDirection == 1) or (vehicle.controlHeld("drivingSeat","right") and self.facingDirection == -1)) and vehicle.controlHeld("drivingSeat","up") then
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[4]*math.pi/180
      end
    elseif ((vehicle.controlHeld("drivingSeat","left") and self.facingDirection == 1) or (vehicle.controlHeld("drivingSeat","right")) and self.facingDirection == -1) then
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[5]*math.pi/180
      end
    else
      for thruster,thrusterStats in pairs(self.thrusters) do
        thrusterStats.thrusterTargetAngle = thrusterStats.thrusterTargets[1]*math.pi/180
      end
    end
    for thruster,thrusterStats in pairs(self.thrusters) do
      thrusterStats.angle = (thrusterStats.angle or 0) + (thrusterStats.thrusterTargetAngle - (thrusterStats.angle or 0)) * thrusterStats.approach
      animator.resetTransformationGroup(thruster)
      animator.rotateTransformationGroup(thruster,thrusterStats.angle,thrusterStats.thrusterCenter)
    end
  end
  
  --Debug
  if self.gunnery then
    for seat, arsenal in pairs(self.gunnery) do
      for arsenalTrigger, subArsenal in pairs(arsenal) do
        for gunName, gun in pairs(subArsenal) do
          local gunCenter = vec2.add(mcontroller.position(), vec2.rotate(vec2.mul(gun.gunCenter, {self.facingDirection, 1}), self.angle))
          local gunTip = vec2.add(gunCenter, vec2.rotate({gun.gunLength, 0},gun.aimAngle+self.angle))
          world.debugLine(gunCenter, vec2.add(gunCenter, vec2.rotate({world.magnitude(gunCenter, vehicle.aimPosition(seat)), 0}, gun.aimAngle + self.angle)), {0, 255, 0})
          if gun.barrels then
            for barrel, barrelOffset in ipairs(gun.barrels) do
              world.debugPoint(vec2.add(gunTip, vec2.rotate(vec2.mul(barrelOffset, {1, self.facingDirection}), gun.aimAngle + self.angle)), "blue")
            end
          else
            world.debugPoint(gunTip, "blue")
          end
        end
      end
    end
  end
end

--Update passenger and driver dance/emote states based on damage to vehicle
function updatePassengers(healthFactor)
  if healthFactor > 0 then
    local maxDamageState = #self.damageStatePassengerDances
    local damageStateIndex = maxDamageState
    damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1

    local dance = self.damageStatePassengerDances[damageStateIndex]
    if (dance ~= "") then
      vehicle.setLoungeDance("passengerSeat",dance)
    end

    --If set, update the timeout and then execture the emote for the damage state
    if self.damageEmoteTimer > 0 then
      self.damageEmoteTimer = self.damageEmoteTimer - script.updateDt()
    else
      maxDamageState = #self.damageStatePassengerEmotes
      damageStateIndex = maxDamageState
      damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
      vehicle.setLoungeEmote("passengerSeat", self.damageStatePassengerEmotes[damageStateIndex])

      maxDamageState = #self.damageStateDriverEmotes
      damageStateIndex = maxDamageState
      damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
      vehicle.setLoungeEmote("drivingSeat", self.damageStateDriverEmotes[damageStateIndex])
    end
  end
end

--Update effects for damage states, such as sound, animation state and emote timers
function updateDriveEffects(healthFactor, driverThisFrame)
  local startSoundName = "engineStart"
  local loopSoundName = "engineLoop"

  --Determine sounds to use for the current state
  if (healthFactor < self.engineDamageSoundThreshold) then
    startSoundName = "engineStartDamaged"
    loopSoundName = "engineLoopDamaged"
  end

  --Check if vehicle is mounted
  if (driverThisFrame ~= nil) then
    --Has vehicle been mounted?
    if (self.driver == nil) then
      animator.playSound(startSoundName)
      if self.mainStates.closing then
        animator.setAnimationState("movement","closing")
      end
    end

    --Is the that is sound active different to the sound that should be active
    if (loopSoundName ~= self.loopPlaying) then
	  --Check if sound is actually playing
      if (self.loopPlaying ~= nil) then
        animator.playSound("damageIntermittent")
        animator.stopAllSounds(self.loopPlaying, 0.5)
      end
      animator.playSound(loopSoundName, -1)
      self.loopPlaying = loopSoundName
    end
  --If vehicle is not mounted
  else
    --Turn off the engine
    if not self.hoverToggled then
      if (self.loopPlaying ~= nil) then
        animator.stopAllSounds(self.loopPlaying, 0.5)
        self.loopPlaying = nil
      end
    end
    --If we were mounted last frame and are no longer, open the cockpit with an animation
    if self.mainStates.opening and self.driver then
      animator.setAnimationState("movement", "opening")
    end
  end

  local rearThrusterFrame = 0
  local ventralThrusterFrame = 0

  --If the engine is runnning, turn on the particle emitters
  if (self.loopPlaying ~= nil) then
    if (self.engineVolume == self.engineIdleVolume) and self.rearThrusterParticles then
      animator.setParticleEmitterActive("rearThrusterIdle", true)
      animator.setParticleEmitterActive("rearThrusterDrive", false)
    elseif self.rearThrusterParticles then
      animator.setParticleEmitterActive("rearThrusterIdle", false)
      animator.setParticleEmitterActive("rearThrusterDrive", true)
      rearThrusterFrame = 3
    end

    --Engine revving - burst of power
    if (self.revEngine == true)  then
      --Set to full power immediately
      self.engineRevTimer = 0.5
      animator.setSoundPitch(self.loopPlaying, self.engineRevPitch, self.engineRevTimer)
      animator.setSoundVolume(self.loopPlaying, self.engineRevVolume, self.engineRevTimer)
      
      if self.ventralThrusterParticles then
        animator.setParticleEmitterActive("ventralThrusterIdle", false)
        animator.setParticleEmitterActive("ventralThrusterJump", true)
        animator.burstParticleEmitter("ventralThrusterJump")
      end
      ventralThrusterFrame = 3

      self.revEngine = false
	--Otherwise gradually reach power, when no revving
    else
      if (self.engineRevTimer > 0.0)  then
        self.engineRevTimer = self.engineRevTimer - script.updateDt()
        ventralThrusterFrame = 3
      else
        if self.ventralThrusterParticles then
          animator.setParticleEmitterActive("ventralThrusterIdle", true)
          animator.setParticleEmitterActive("ventralThrusterJump", false)
        end
        --Settling to the normal engine pitch and volume
        animator.setSoundPitch(self.loopPlaying, self.enginePitch, 1.5)
        animator.setSoundVolume(self.loopPlaying, self.engineVolume, 1.5)
      end
    end

    for thruster, thrusterStats in pairs(self.thrusters) do
      animator.setAnimationState(thruster, "on")
    end
  else
    if self.rearThrusterParticles then
      animator.setParticleEmitterActive("rearThrusterIdle", false)
      animator.setParticleEmitterActive("rearThrusterDrive", false)
    end
    if self.ventralThrusterParticles then
      animator.setParticleEmitterActive("ventralThrusterIdle", false)
      animator.setParticleEmitterActive("ventralThrusterJump", false)
    end
    for thruster, thrusterStats in pairs(self.thrusters) do
      animator.setAnimationState(thruster, "off")
    end
  end

  --If vehicle is burning, take damage intermittantly
  if (self.loopPlaying ~= nil or (self.onFireThreshold and healthFactor < self.onFireThreshold)) then
    --Time between damage sounds
    if (healthFactor < self.intermittentDamageSoundThreshold) then
      self.damageSoundTimer = self.damageSoundTimer - script.updateDt()

      if (self.damageSoundTimer <= 0) then
        animator.playSound("damageIntermittent")

        --A random time that changes depending on how damaged the vehicle is
        local randomMax = (healthFactor * self.damageSoundInterval[2]) + ((1.0 - healthFactor) * self.damageSoundInterval[1])

        animator.burstParticleEmitter("damageIntermittent")
        self.damageEmoteTimer = config.getParameter("damageEmoteTime")

        self.damageSoundTimer = math.random() * randomMax;
      end
    end
  end

  rearThrusterFrame = rearThrusterFrame + math.random(3)
  animator.setGlobalTag("rearThrusterFrame", rearThrusterFrame)

  ventralThrusterFrame = ventralThrusterFrame + math.random(3)
  animator.setGlobalTag("bottomThrusterFrame", ventralThrusterFrame)
end

--Update visual effects based on the damage taken and whether we have our headlights on
function updateVisualEffects(currentHealth, damage, headlights)
  local maxDamageState = #self.damageStateNames
  local prevHealthFactor = currentHealth / self.stats.health

  --Determine health factor
  local newHealthFactor = (currentHealth - damage) / self.stats.health

  --Determine which damage state we are in PRIOR to the damage taken
  local previousDamageStateIndex = maxDamageState
  if prevHealthFactor > 0 then
    previousDamageStateIndex = (maxDamageState - math.ceil(prevHealthFactor * maxDamageState)) + 1
  end

  --Determine which damage state we are in AFTER the damage is taken
  local damageStateIndex = maxDamageState
  if newHealthFactor > 0 then
    damageStateIndex = (maxDamageState - math.ceil(newHealthFactor * maxDamageState)) + 1
  end

  --If we have changed our damage state, update effects with some damage particles to add impact
  if (damageStateIndex > previousDamageStateIndex) then
    animator.burstParticleEmitter("damageShards")
    animator.playSound("changeDamageState")
  end

  --Update headlights
  switchHeadLights(previousDamageStateIndex, damageStateIndex, headlights)

  --Set damage state tag to update frames
  animator.setGlobalTag("damageState", self.damageStateNames[damageStateIndex])

  --Smoke particles and fire
  if newHealthFactor < 1.0 then
    if (self.smokeThreshold > 0 and newHealthFactor < self.smokeThreshold) then
      local smokeFactor = 1.0 - (newHealthFactor / self.smokeThreshold)
      animator.setParticleEmitterActive("smoke", true)
      animator.setParticleEmitterEmissionRate("smoke", smokeFactor * self.maxSmokeRate)
    end

    if (self.fireThreshold > 0 and newHealthFactor < self.fireThreshold) then
      local fireFactor = 1.0 - (newHealthFactor / self.fireThreshold)
      animator.setParticleEmitterActive("fire", true)
      animator.setParticleEmitterEmissionRate("fire", fireFactor * self.maxFireRate)
    end

    if (self.onFireThreshold and newHealthFactor < self.onFireThreshold) then
      animator.setAnimationState("onfire", "on")
    else
      animator.setAnimationState("onfire", "off")
    end
  else
    animator.setParticleEmitterActive("smoke", false)
    animator.setParticleEmitterActive("fire", false)
    animator.setAnimationState("onfire", "off")
  end
end

--Update headlights with the new states
function switchHeadLights(oldIndex, newIndex, activate)
  if (activate ~= self.headlightsOn or oldIndex ~= newIndex) then
    local listOfLists = config.getParameter("lightsInDamageState")

    if (listOfLists ~= nil) then
      if (oldIndex ~= newIndex) then
        local listToSwitchOff = listOfLists[oldIndex]
        for i, name in ipairs(listToSwitchOff) do
          animator.setLightActive(name, false)
        end
      end

        local listToSwitchOn = listOfLists[newIndex]
        for i, name in ipairs(listToSwitchOn) do
        animator.setLightActive(name, activate)
      end
    end
    self.headlightsOn = activate

    if (self.headlightsOn) then
      animator.setAnimationState("headlights", "on")
    elseif self.primaryHeadlight or self.altFireHeadlight then
      animator.setAnimationState("headlights", "off")
    end
  end
end

--Update emotes and dances
function setDamageEmotes()
  local damageTakenEmote = config.getParameter("damageTakenEmote")
  self.damageEmoteTimer = config.getParameter("damageEmoteTime")
  vehicle.setLoungeEmote("drivingSeat", damageTakenEmote)
  vehicle.setLoungeEmote("passengerSeat", damageTakenEmote)
end

--Determine damage taken, resistances and other functions
function applyDamage(damageRequest)
  --Determine how much damage was taken
  local damage = 0
  if damageRequest.damageType == "Damage" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, self.stats.protection)
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  else
    return {}
  end
  
  local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
  local resistance = self.stats.elementalResistances and self.stats.elementalResistances[elementalStat] or 0.0
  damage = damage - (resistance * damage)

  local knockbackFactor = (1 - (self.stats.grit or 0.0))

  local knockbackMomentum = vec2.mul(damageRequest.knockbackMomentum, knockbackFactor)
  local knockback = vec2.mag(knockbackMomentum)
  if knockback > self.stats.knockbackThreshold or 1.0 then
    local dir = knockbackMomentum[1] > 0 and 1 or -1
    mcontroller.addMomentum({dir * knockback / 1.41, knockback / 1.41})
  end

  setDamageEmotes()

  updateVisualEffects(storage.health, damage, self.headlightsOn)

  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost

  --Return the modified damage request
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = storage.health <= 0 and "Kill" or "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end

function selfDamageNotifications()
  local selfDamageNotification = self.selfDamageNotifications
  self.selfDamageNotifications = {}
  return selfDamageNotification
end

--TODO
--Movement functionality
function move()
  local groundDistance = minimumSpringDistance(self.bodySpringPositions)
  local nearGround = groundDistance < self.nearGroundDistance

  --assume idle pitch
  self.enginePitch = self.engineIdlePitch;
  self.engineVolume = self.engineIdleVolume;
  
  if self.facingDirection < 0 and self.movementSettings.leftCollisionPoly then
    self.movementSettings.collisionPoly = self.movementSettings.leftCollisionPoly
  elseif self.movementSettings.leftCollisionPoly then
    self.movementSettings.collisionPoly = self.movementSettings.rightCollisionPoly
  end
  mcontroller.resetParameters(self.movementSettings)
  
  
  
  if self.driver then
    mcontroller.applyParameters(self.occupiedMovementSettings)
    if groundDistance <= self.hoverTargetDistance then
      mcontroller.approachVelocityAlongAngle(math.pi/2,(self.hoverTargetDistance - groundDistance) * self.hoverVelocityFactor, self.hoverControlForce,true)
    end
    targetAngle = 0
  else
    if self.baseRotationOnVelocity then
      targetAngle = 0
    end
    if self.hoverToggled then
      mcontroller.applyParameters(self.occupiedMovementSettings)
      if groundDistance <= self.hoverTargetDistance then
        mcontroller.approachVelocityAlongAngle(math.pi/2,(self.hoverTargetDistance - groundDistance) * self.hoverVelocityFactor, self.hoverControlForce,true)
      end
    end
  end
  
  if vehicle.controlHeld("drivingSeat", "jump") then
    if not self.holdingJumpLastFrame then
      self.spaceToggled = not self.spaceToggled
    end
    self.holdingJumpLastFrame = true
  else
    self.holdingJumpLastFrame = false
  end
  
  if self.hoverToggle then
    self.hoverToggled = self.spaceToggled
  end
  if self.hoverToggled and self.hoverToggleControlForce then
    mcontroller.approachYVelocity(0, self.hoverToggleControlForce)
    mcontroller.approachXVelocity(0, self.hoverToggleControlForce)
  end
  if vehicle.controlHeld("drivingSeat", "left") and not self.hoverToggled then
    mcontroller.approachXVelocity(-self.targetVelocity[1], self.velocityControlForces.horizontal)
    if self.baseRotationOnVelocity then
      targetAngle = math.atan(mcontroller.yVelocity(), math.max(math.abs(mcontroller.xVelocity()),10))
      targetAngle = (self.facingDirection < 0) and -targetAngle or targetAngle
    end
    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  elseif vehicle.controlHeld("drivingSeat", "right") and not self.hoverToggled then
    mcontroller.approachXVelocity(self.targetVelocity[1], self.velocityControlForces.horizontal)
    if self.baseRotationOnVelocity then
      targetAngle = math.atan(mcontroller.yVelocity(),math.max(math.abs(mcontroller.xVelocity()),10))
      targetAngle = (self.facingDirection < 0) and -targetAngle or targetAngle
    end
    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  end
  if vehicle.controlHeld("drivingSeat", "up") and not self.hoverToggled then
    if not self.baseRotationOnVelocity then
      local targetAngle = (self.facingDirection < 0) and -self.maxAngle or self.maxAngle
      self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
    end
    self.enginePitch = self.engineRevPitch
    self.engineVolume = self.engineRevVolume
    if self.canFly then
      mcontroller.approachYVelocity(self.targetVelocity[2], self.velocityControlForces.upward)
    end
  elseif vehicle.controlHeld("drivingSeat", "down") and not self.hoverToggled then
    if not self.baseRotationOnVelocity then
      local targetAngle = (self.facingDirection < 0) and self.maxAngle or -self.maxAngle
      self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
    end
    if self.canFly then
      mcontroller.approachYVelocity(-self.targetVelocity[2], self.velocityControlForces.downward)
    end
  else
    local frontSpringDistance = minimumSpringDistance(self.frontSpringPositions)
    local backSpringDistance = minimumSpringDistance(self.backSpringPositions)
    if frontSpringDistance == self.groundSearchMagnitude and backSpringDistance == self.groundSearchMagnitude then
      self.angle = self.angle - self.angle * self.angleApproachFactor
    else
      self.angle = self.angle + math.atan((backSpringDistance - frontSpringDistance) * self.equaliseFactor)
      self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
    end
  end
  if self.baseRotationOnVelocity then
    self.angle = self.angle + (targetAngle - self.angle) * self.velocityRotationApproachFactor
    self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
  end
  if self.continuousAngleCheck then
    self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
  end

  if nearGround and self.canLaunch then
    if self.jumpTimer <= 0 and vehicle.controlHeld("drivingSeat", "jump") then
      mcontroller.setYVelocity(self.launchVelocity)
      self.jumpTimer = self.launchTimeout
      self.revEngine = true;
    else
      self.jumpTimer = self.jumpTimer - script.updateDt()
    end
  else
    self.jumpTimer = self.launchTimeout
  end

  mcontroller.setRotation(self.angle)
end

function controls()
  if (vehicle.controlHeld("drivingSeat", "PrimaryFire")) and self.primaryHeadlight then
    if (self.headlightCanToggle) then
      updateVisualEffects(storage.health, 0, (not self.headlightsOn))
      if (self.headlightsOn) then
        animator.playSound("headlightSwitchOn")
      else
        animator.playSound("headlightSwitchOff")
      end
      self.headlightCanToggle = false
    end
  else
    self.headlightCanToggle = true;
  end
  
  if self.gunnery then
    for seat,arsenal in pairs(self.gunnery) do
      for arsenalTrigger,subarsenal in pairs(arsenal) do
        if (vehicle.controlHeld(seat, arsenalTrigger)) then
          for gunName,gun in pairs(subarsenal) do
            fireSubarsenal(seat,subarsenal,gunName,gun,gun.punishSlaves)
          end
        end
      end
    end
    for seat,arsenal in pairs(self.gunnery) do
      for arsenalTrigger,subarsenal in pairs(arsenal) do
        if (vehicle.controlHeld(seat, arsenalTrigger)) then
          for gunName,gun in pairs(subarsenal) do
            fireSubarsenal(seat,subarsenal,gunName,gun,not gun.punishSlaves)
          end
        end
      end
    end
  end

  if (vehicle.controlHeld("drivingSeat", "AltFire")) and self.altFireHorn then
    if not self.hornPlaying then
      animator.playSound("hornLoop", -1)
      self.hornPlaying = true;
    end
  else
    if self.hornPlaying then
      animator.stopAllSounds("hornLoop")
      self.hornPlaying = false;
    end
  end
end

function fireSubarsenal(seat,subarsenal,gunName,gun,condition)
  if gun.cooldown == 0 and condition then
    local gunCenter = vec2.add(mcontroller.position(),vec2.rotate(vec2.mul(gun.gunCenter,{self.facingDirection,1}),self.angle))
    local gunTip = vec2.add(gunCenter,vec2.rotate({gun.gunLength,0},gun.aimAngle+self.angle))
    if gun.firingType == "flak" then
      local speed = gun.projectileParams.speed or root.projectileConfig(gun.projectileType).speed
      gun.projectileParams.timeToLive = world.magnitude(gunTip,vehicle.aimPosition(seat)) / speed
    end
    if gun.firingType == "laser" and gun.activeCooldown == 0 then
      gun.activeCooldown = gun.activeTime
      gun.cooldown = gun.fireTime
      gun.weakActiveCooldown = gun.weakActiveTime or 0
      for i,damageSource in ipairs(gun.damageSourceList) do
        vehicle.setDamageSourceEnabled(damageSource,true)
      end
    elseif gun.firingType ~= "laser" then
      if gun.barrels then
        for barrelI,barrelOffset in ipairs(gun.barrels) do
          fireProjectile(gun.projectileType,gun.projectileParams,gun.inaccuracy,vec2.add(gunTip,vec2.rotate(vec2.mul(barrelOffset,{1,self.facingDirection}),gun.aimAngle+self.angle)),gun.projectileCount,gun.fireTime,util.wrapAngle(gun.aimAngle+self.angle))
        end
      else
        fireProjectile(gun.projectileType,gun.projectileParams,gun.inaccuracy,gunTip,gun.projectileCount,gun.fireTime,util.wrapAngle(gun.aimAngle+self.angle))
      end
      gun.cooldown = gun.fireTime
    end
    if gun.punishSlaves then
      for slave,punishment in pairs(gun.punishSlaves) do
        if subarsenal[slave] then
          subarsenal[slave].cooldown = punishment
        else
          for slaveName,slaveGun in pairs(subarsenal) do
            if slaveGun.gunName == slave then
              slaveGun.cooldown = punishment
            end
          end
        end
      end
    end
    if gun.playSounds then
      for i,sound in ipairs(gun.playSounds) do
        animator.playSound(sound)
      end
    end
    if gun.setAnimationStates then
      for animation,state in pairs(gun.setAnimationStates) do
        animator.setAnimationState(animation,type(state) == "table" and state[1] or state,type(state) == "table" and state[2] or false)
      end
    end
  end
end

function animate()
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)
end

function updateDamage()
  if animator.animationState("onfire") == "on" then
    setDamageEmotes()

    local damageThisFrame = self.damagePerSecondWhenOnFire * script.updateDt()
    updateVisualEffects(storage.health, damageThisFrame, self.headlightsOn)
    storage.health = storage.health - damageThisFrame
  end

  if storage.health <= 0 then
    animator.burstParticleEmitter("damageShards")
    animator.burstParticleEmitter("wreckage")
    animator.playSound("explode")

    local projectileConfig = {
      damageTeam = { type = "indiscriminate" },
      power = config.getParameter("explosionDamage"),
      onlyHitTerrain = false,
      timeToLive = 0,
      actionOnReap = {
        {
          action = "config",
          file =  config.getParameter("explosionConfig")
        }
      }
    }
    world.spawnProjectile("invisibleprojectile", mcontroller.position(), 0, {0, 0}, false, projectileConfig)

    vehicle.destroy()
  end

  local newPosition = mcontroller.position()
  local newVelocity = vec2.div(vec2.sub(newPosition, self.lastPosition), script.updateDt())
  self.lastPosition = newPosition

  if mcontroller.isColliding() then
    function findMaxAccel(trackedVelocities)
      local maxAccel = 0
      for _, v in ipairs(trackedVelocities) do
        local accel = vec2.mag(vec2.sub(newVelocity, v))
        if accel > maxAccel then
          maxAccel = accel
        end
      end
      return maxAccel
    end

    if findMaxAccel(self.collisionDamageTrackingVelocities) >= self.minDamageCollisionAccel then
      animator.playSound("collisionDamage")
      setDamageEmotes()

      updateVisualEffects(storage.health, self.terrainCollisionDamage, self.headlightsOn)

      storage.health = storage.health - self.terrainCollisionDamage
      self.collisionDamageTrackingVelocities = {}
      self.collisionNotificationTrackingVelocities = {}

      table.insert(self.selfDamageNotifications, {
        sourceEntityId = entity.id(),
        targetEntityId = entity.id(),
        position = mcontroller.position(),
        damageDealt = self.terrainCollisionDamage,
        healthLost = self.terrainCollisionDamage,
        hitType = "Hit",
        damageSourceKind = self.terrainCollisionDamageSourceKind,
        targetMaterialKind = self.materialKind,
        killed = storage.health <= 0
      })
    end

    if findMaxAccel(self.collisionNotificationTrackingVelocities) >= self.minNotificationCollisionAccel then
      animator.playSound("collisionNotification")
      self.collisionNotificationTrackingVelocities = {}
    end
  end

  function appendTrackingVelocity(trackedVelocities, newVelocity)
    table.insert(trackedVelocities, newVelocity)
    while #trackedVelocities > self.accelerationTrackingCount do
      table.remove(trackedVelocities, 1)
    end
  end

  appendTrackingVelocity(self.collisionDamageTrackingVelocities, newVelocity)
  appendTrackingVelocity(self.collisionNotificationTrackingVelocities, newVelocity)
end

function fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount, cooldown, aimAngle)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
  
    projectileId = world.spawnProjectile(
        projectileType,
        firePosition,
        entity.id(),
        aimVector(inaccuracy or self.inaccuracy or 0,aimAngle),
        false,
        params
      )
  end
  self.cooldown = cooldown
  return projectileId
end

function aimVector(inaccuracy, aimAngle)
  local aimVector = vec2.rotate({1, 0}, aimAngle + sb.nrand(inaccuracy, 0))
  return aimVector
end

function minimumSpringDistance(points)
  local min = nil
  for _, point in ipairs(points) do
  point = vec2.rotate(point, self.angle)
  point = vec2.add(point, mcontroller.position())
  local magnitude = magnitudeToGround(point)
  if min == nil or magnitude < min then
    min = magnitude
  end
  end
  return min
end

function magnitudeToGround(point)
  local endPoint = vec2.add(point, {0, -self.groundSearchMagnitude})

  world.debugLine(point, endPoint, "yellow")
  local intPoint = world.lineCollision(point, endPoint)

  if intPoint then
  world.debugPoint(intPoint, "red")
  return point[2] - intPoint[2]
  else
  return self.groundSearchMagnitude
  end
end