require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

PlasmaCannon = WeaponAbility:new()

function PlasmaCannon:init()
	self.cooldownTimer = self.cooldownTime
end

function PlasmaCannon:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.weapon.currentAbility == nil 
	and self.fireMode == (self.activatingFireMode or self.abilitySlot) 
	and self.cooldownTimer == 0 
	and not status.resourceLocked("energy") 
	and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		self:setState(self.windup)
	end
end

function PlasmaCannon:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	util.wait(self.stances.windup.duration)

	self:setState(self.fire)
end

function PlasmaCannon:fire()
	if self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", self.energyUsage) then
		self.weapon:setStance(self.stances.fire)
		self.weapon:updateAim()

		local params = copy(self.projectileParameters)
		params.power = self.baseDamage * config.getParameter("damageLevelMultiplier")
		params.powerMultiplier = activeItem.ownerPowerMultiplier()
		params.speed = util.randomInRange(params.speed)

		world.spawnProjectile(self.projectileType, self:firePosition(), activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}, false, params)

		animator.playSound("cannonFire")

		util.wait(self.stances.fire.duration)

		self:setState(self.wait)
	end

	self.cooldownTimer = self.cooldownTime
end

function PlasmaCannon:wait()
	self.weapon:setStance(self.stances.wait)
	self.weapon:updateAim()

	util.wait(self.stances.wait.duration)

	local progress = 0
	util.wait(self.stances.wait.duration, function()
		local from = self.stances.wait.weaponOffset or {0,0}
		local to = self.stances.fire.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.wait.weaponRotation, self.stances.fire.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.wait.armRotation, self.stances.fire.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.wait.duration))
	end)

	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		if not status.resourceLocked("energy") then 
			self:setState(self.fire)
			break
		elseif status.resourceLocked("energy") then
			break
		end
	end
end

function PlasmaCannon:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("swoosh", "projectileSource")))
end

function PlasmaCannon:uninit()
end