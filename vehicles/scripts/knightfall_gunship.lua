require("/scripts/vec2.lua")
require("/scripts/util.lua")

-- Credits to Miknyes and Travelling Merchant for giving me access to this script! All credits goes to them. --

function init()
	self.levelApproachFactor = config.getParameter("levelApproachFactor")
	self.angleApproachFactor = config.getParameter("angleApproachFactor")
	self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")
	self.maxAngle = config.getParameter("maxAngle") * math.pi / 180
	self.constantAngleCheck = config.getParameter("constantAngleCheck")
	self.velocityRotation = config.getParameter("velocityRotation")
	self.velocityRotationApproach = config.getParameter("velocityRotationApproach")
	self.verticalRotationThreshold = config.getParameter("verticalRotationThreshold")
	self.hoverTargetDistance = config.getParameter("hoverTargetDistance")
	self.hoverVelocityFactor = config.getParameter("hoverVelocityFactor")
	self.hoverControlForce = config.getParameter("hoverControlForce")
	self.targetHorizontalVelocity = config.getParameter("targetHorizontalVelocity")
	self.horizontalControlForce = config.getParameter("horizontalControlForce")
	self.targetUpwardVelocity = config.getParameter("targetUpwardVelocity")
	self.upwardControlForce = config.getParameter("upwardControlForce")
	self.targetDownwardVelocity = config.getParameter("targetDownwardVelocity")
	self.downwardControlForce = config.getParameter("downwardControlForce")
	self.spinFriction = config.getParameter("spinFriction")
	self.primaryFireHeadlight = config.getParameter("primaryFireHeadlight")
	self.canFly = config.getParameter("canFly")
	self.canJump = config.getParameter("canJump")
	self.nearGroundDistance = config.getParameter("nearGroundDistance")
	self.jumpVelocity = config.getParameter("jumpVelocity")
	self.jumpTimeout = config.getParameter("jumpTimeout")
	self.backSpringPositions = config.getParameter("backSpringPositions")
	self.frontSpringPositions = config.getParameter("frontSpringPositions")
	self.bodySpringPositions = config.getParameter("bodySpringPositions")
	self.movementSettings = config.getParameter("movementSettings")
	self.occupiedMovementSettings = config.getParameter("occupiedMovementSettings")
	self.zeroGMovementSettings = config.getParameter("zeroGMovementSettings")
	self.protection = config.getParameter("protection")
	self.maxHealth = config.getParameter("maxHealth")
	self.hoverToggle = config.getParameter("hoverToggle")
	self.hoverToggleControlForce = config.getParameter("hoverToggleControlForce")

	self.smokeThreshold =	config.getParameter("smokeParticleHealthThreshold")
	self.fireThreshold =	config.getParameter("fireParticleHealthThreshold")
	self.maxSmokeRate = config.getParameter("smokeRateAtZeroHealth")
	self.maxFireRate = config.getParameter("fireRateAtZeroHealth")

	self.onFireThreshold =	config.getParameter("onFireHealthThreshold")
	self.damagePerSecondWhenOnFire =	config.getParameter("damagePerSecondWhenOnFire")

	self.engineDamageSoundThreshold =	config.getParameter("engineDamageSoundThreshold")
	self.intermittentDamageSoundThreshold = config.getParameter("intermittentDamageSoundThreshold")

	--this is a range
	self.maxDamageSoundInterval = config.getParameter("maxDamageSoundInterval")
	self.minDamageSoundInterval = config.getParameter("minDamageSoundInterval")

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

	--initial state
	self.headlightCanToggle = true
	self.headlightsOn = false
	self.hornPlaying = false
	
	if self.primaryFireHeadlight or self.altFireHeadlight then
		animator.setAnimationState("headlights", "off")
	end

	--this comes in from the controller.
	self.ownerKey = config.getParameter("ownerKey")
	vehicle.setPersistent(self.ownerKey)

	--assume maxhealth
	if not (storage.health) then
		local startHealthFactor = config.getParameter("startHealthFactor")

		if (startHealthFactor == nil) then
				storage.health = self.maxHealth
		else
			 storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
		end
		animator.setAnimationState("movement", "warpInPart1")
	end

	--setup the store functionality
	message.setHandler("store",
			function(_, _, ownerKey)
				if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil) then
					animator.setAnimationState("movement", "warpOutPart1")
					if self.primaryFireHeadlight or self.altFireHeadlight then
						switchHeadLights(1, 1, false)
					end
					animator.playSound("returnvehicle")
					return {storable = true, healthFactor = storage.health / self.maxHealth}
				else
					return {storable = false, healthFactor = storage.health / self.maxHealth}
				end
			end)
			
	--setup the kms functionality
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

	if mcontroller.atWorldLimit() then
		vehicle.destroy()
		return
	end

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

		local healthFactor = storage.health / self.maxHealth

		move()
		controls()
		animate()
		updateDamage()
		updateDriveEffects(healthFactor, driverThisFrame)

		updatePassengers(healthFactor)

		if self.leveledGroups then
			for group,center in pairs(self.leveledGroups) do
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
	
	--debug
	if self.gunnery then
		for seat,arsenal in pairs(self.gunnery) do
			for arsenalTrigger,subarsenal in pairs(arsenal) do
				for gunName,gun in pairs(subarsenal) do
					local gunCenter = vec2.add(mcontroller.position(),vec2.rotate(vec2.mul(gun.gunCenter,{self.facingDirection,1}),self.angle))
					local gunTip = vec2.add(gunCenter,vec2.rotate({gun.gunLength,0},gun.aimAngle+self.angle))
					world.debugLine(gunCenter,vec2.add(gunCenter,vec2.rotate({world.magnitude(gunCenter,vehicle.aimPosition(seat)),0},gun.aimAngle+self.angle)),{0,255,0})
					if gun.barrels then
						for barrel,barrelOffset in ipairs(gun.barrels) do
							world.debugPoint(vec2.add(gunTip,vec2.rotate(vec2.mul(barrelOffset,{1,self.facingDirection}),gun.aimAngle+self.angle)), "blue")
						end
					else
						world.debugPoint(gunTip, "blue")
					end
				end
			end
		end
	end
end

--make the driver and passenger dance and emote according to the damage state of the vehicle
function updatePassengers(healthFactor)
	if healthFactor > 0 then
		local maxDamageState = #self.damageStatePassengerDances
		local damageStateIndex = maxDamageState
		damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1

		local dance = self.damageStatePassengerDances[damageStateIndex]
		if (dance ~= "") then
			vehicle.setLoungeDance("passengerSeat",dance)
		end

		--if we have a scared face on because of taking damage
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

function updateDriveEffects(healthFactor, driverThisFrame)
	local startSoundName = "engineStart"
	local loopSoundName = "engineLoop"

	if (healthFactor < self.engineDamageSoundThreshold) then
		startSoundName = "engineStartDamaged"
		loopSoundName = "engineLoopDamaged"
	end

	--do we have a driver ?
	if (driverThisFrame ~= nil) then
		--has someone got in ?
		if (self.driver == nil) then
			animator.playSound(startSoundName)
			if self.mainStates.closing then
				animator.setAnimationState("movement","closing")
			end
		end

		--is the sound we want different to the sound we have ?
		if (loopSoundName ~= self.loopPlaying) then
			if (self.loopPlaying ~= nil) then
				animator.playSound("damageIntermittent")
				animator.stopAllSounds(self.loopPlaying, 0.5)
			end
			animator.playSound(loopSoundName, -1)
			self.loopPlaying = loopSoundName
		end
	else
		--no driver, stop the engine
		if not self.hoverToggled then
			if (self.loopPlaying ~= nil) then
				animator.stopAllSounds(self.loopPlaying, 0.5)
				self.loopPlaying = nil
			end
		end
		-- driver last frame, open the cockpit
		if self.mainStates.opening and self.driver then
			animator.setAnimationState("movement","opening")
		end
	end

	local rearThrusterFrame = 0
	local ventralThrusterFrame = 0

	-- is the engine sound playing ?
	if (self.loopPlaying ~= nil) then
		if (self.engineVolume == self.engineIdleVolume) and self.rearThrusterParticles then
			animator.setParticleEmitterActive("rearThrusterIdle", true)
			animator.setParticleEmitterActive("rearThrusterDrive", false)
		elseif self.rearThrusterParticles then
			animator.setParticleEmitterActive("rearThrusterIdle", false)
			animator.setParticleEmitterActive("rearThrusterDrive", true)
			rearThrusterFrame = 3
		end

		-- a brief burst of power
		if (self.revEngine == true)	then
			-- instantly set them to full power.
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
		else
			if (self.engineRevTimer > 0.0)	then
				self.engineRevTimer = self.engineRevTimer - script.updateDt()
				ventralThrusterFrame = 3
			else
				if self.ventralThrusterParticles then
					animator.setParticleEmitterActive("ventralThrusterIdle", true)
					animator.setParticleEmitterActive("ventralThrusterJump", false)
				end
				--settling to the normal engine pitch and volume
				animator.setSoundPitch(self.loopPlaying, self.enginePitch, 1.5)
				animator.setSoundVolume(self.loopPlaying, self.engineVolume, 1.5)
			end
		end

		for thruster,thrusterStats in pairs(self.thrusters) do
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
		for thruster,thrusterStats in pairs(self.thrusters) do
		animator.setAnimationState(thruster, "off")
	end
	end

	--if burning, takew dammage intermittantly.
	if (self.loopPlaying ~= nil or (self.onFireThreshold and healthFactor < self.onFireThreshold)) then
		--time to go snap crackle or pop ?
		if (healthFactor < self.intermittentDamageSoundThreshold) then
			self.damageSoundTimer = self.damageSoundTimer - script.updateDt()

			if (self.damageSoundTimer <= 0) then
				animator.playSound("damageIntermittent")

				--a random time that changes depending on how damaged the vehicle is.
				local randomMax = (healthFactor * self.maxDamageSoundInterval) + ((1.0 - healthFactor) * self.minDamageSoundInterval)

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

function updateVisualEffects(currentHealth, damage, headlights)

	local maxDamageState = #self.damageStateNames
	local prevHealthFactor = currentHealth / self.maxHealth

	--work out the factor after damage occurs.
	local newHealthFactor = (currentHealth - damage) / self.maxHealth

	--work out what damage state we are in before damage occurs
	local previousDamageStateIndex = maxDamageState
	if prevHealthFactor > 0 then
		previousDamageStateIndex = (maxDamageState - math.ceil(prevHealthFactor * maxDamageState)) + 1
	end

	--now the damage state after damage occurs
	local damageStateIndex = maxDamageState
	if newHealthFactor > 0 then
		damageStateIndex = (maxDamageState - math.ceil(newHealthFactor * maxDamageState)) + 1
	end

	--if we've changed damage state make some danaged effects.
	if (damageStateIndex > previousDamageStateIndex) then
		animator.burstParticleEmitter("damageShards")
		animator.playSound("changeDamageState")
	end

	switchHeadLights(previousDamageStateIndex, damageStateIndex, headlights)

	animator.setGlobalTag("damageState", self.damageStateNames[damageStateIndex])

	--smoke particles and fire
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
		elseif self.primaryFireHeadlight or self.altFireHeadlight then
			animator.setAnimationState("headlights", "off")
		end
	end
end

function setDamageEmotes()
	local damageTakenEmote = config.getParameter("damageTakenEmote")
	self.damageEmoteTimer = config.getParameter("damageEmoteTime")
	vehicle.setLoungeEmote("drivingSeat", damageTakenEmote)
	vehicle.setLoungeEmote("passengerSeat", damageTakenEmote)
end

function applyDamage(damageRequest)
	local damage = 0
	if damageRequest.damageType == "Damage" then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
	elseif damageRequest.damageType == "IgnoresDef" then
		damage = damage + damageRequest.damage
	else
		return {}
	end

	setDamageEmotes()

	updateVisualEffects(storage.health, damage, self.headlightsOn)

	local healthLost = math.min(damage, storage.health)
	storage.health = storage.health - healthLost

	return {{
		sourceEntityId = damageRequest.sourceEntityId,
		targetEntityId = entity.id(),
		position = mcontroller.position(),
		damageDealt = damage,
		healthLost = healthLost,
		hitType = "Hit",
		damageSourceKind = damageRequest.damageSourceKind,
		targetMaterialKind = self.materialKind,
		killed = storage.health <= 0
	}}
end

function selfDamageNotifications()
	local sdn = self.selfDamageNotifications
	self.selfDamageNotifications = {}
	return sdn
end

function move()
	self.spin = 0

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
		if self.velocityRotation then
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
		mcontroller.approachXVelocity(-self.targetHorizontalVelocity, self.horizontalControlForce)
		if self.velocityRotation then
			targetAngle = math.atan(mcontroller.yVelocity(),math.max(math.abs(mcontroller.xVelocity()),10))
			targetAngle = (self.facingDirection < 0) and -targetAngle or targetAngle
		end
		self.enginePitch = self.engineRevPitch;
		self.engineVolume = self.engineRevVolume;
	elseif vehicle.controlHeld("drivingSeat", "right") and not self.hoverToggled then
		mcontroller.approachXVelocity(self.targetHorizontalVelocity, self.horizontalControlForce)
		if self.velocityRotation then
			targetAngle = math.atan(mcontroller.yVelocity(),math.max(math.abs(mcontroller.xVelocity()),10))
			targetAngle = (self.facingDirection < 0) and -targetAngle or targetAngle
		end
		self.enginePitch = self.engineRevPitch;
		self.engineVolume = self.engineRevVolume;
	end
	if vehicle.controlHeld("drivingSeat", "up") and not self.hoverToggled then
		if not self.velocityRotation then
			local targetAngle = (self.facingDirection < 0) and -self.maxAngle or self.maxAngle
			self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
		end
		self.enginePitch = self.engineRevPitch
		self.engineVolume = self.engineRevVolume
		if self.canFly then
			mcontroller.approachYVelocity(self.targetUpwardVelocity, self.upwardControlForce)
		end
	elseif vehicle.controlHeld("drivingSeat", "down") and not self.hoverToggled then
		if not self.velocityRotation then
			local targetAngle = (self.facingDirection < 0) and self.maxAngle or -self.maxAngle
			self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
		end
		if self.canFly then
			mcontroller.approachYVelocity(self.targetDownwardVelocity, self.downwardControlForce)
		end
	else
		local frontSpringDistance = minimumSpringDistance(self.frontSpringPositions)
		local backSpringDistance = minimumSpringDistance(self.backSpringPositions)
		if frontSpringDistance == self.maxGroundSearchDistance and backSpringDistance == self.maxGroundSearchDistance then
			self.angle = self.angle - self.angle * self.angleApproachFactor
		else
			self.angle = self.angle + math.atan((backSpringDistance - frontSpringDistance) * self.levelApproachFactor)
			self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
		end
	end
	if self.velocityRotation then
		self.angle = self.angle + (targetAngle - self.angle) * self.velocityRotationApproach
		self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
	end
	if self.constantAngleCheck then
		self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
	end

	if nearGround and self.canJump then
		if self.jumpTimer <= 0 and vehicle.controlHeld("drivingSeat", "jump") then
			mcontroller.setYVelocity(self.jumpVelocity)
			self.jumpTimer = self.jumpTimeout
			self.revEngine = true;
		else
			self.jumpTimer = self.jumpTimer - script.updateDt()
		end
	else
		self.jumpTimer = self.jumpTimeout
	end

	mcontroller.setRotation(self.angle)
end

function controls()
	if (vehicle.controlHeld("drivingSeat", "PrimaryFire")) and self.primaryFireHeadlight then
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
					file =	config.getParameter("explosionConfig")
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

function aimVector(inaccuracy,aimAngle)
	local aimVector = vec2.rotate({1, 0}, aimAngle + sb.nrand(inaccuracy, 0))
	return aimVector
end

function minimumSpringDistance(points)
	local min = nil
	for _, point in ipairs(points) do
		point = vec2.rotate(point, self.angle)
		point = vec2.add(point, mcontroller.position())
		local d = distanceToGround(point)
		if min == nil or d < min then
			min = d
		end
	end
	return min
end

function distanceToGround(point)
	local endPoint = vec2.add(point, {0, -self.maxGroundSearchDistance})

	world.debugLine(point, endPoint, {255, 255, 0, 255})
	local intPoint = world.lineCollision(point, endPoint)

	if intPoint then
		world.debugPoint(intPoint, {255, 255, 0, 255})
		return point[2] - intPoint[2]
	else
		return self.maxGroundSearchDistance
	end
end
