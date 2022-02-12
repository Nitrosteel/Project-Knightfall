--better random speed thing, for shot guns

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end
	
	-- altfire.lua copies primary ability parameters and that's stupid and i hate it
	if not self._altspeedfixed then
		if self.projectileParameters.speed and self.abilitySlot == "alt" then
			local a = config.getParameter("altAbility")
			if not a or not a.projectileParameters or not a.projectileParameters.speed then
				self.projectileParameters.speed = nil
			end
		end
		self._altspeedfixed = true
	end
	--
	
	local speed = projectileParams and projectileParams.speed or self.projectileParameters.speed

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
		params.speed = util.randomInRange(speed)

    projectileId = world.spawnProjectile(
			projectileType,
			firePosition or self:firePosition(),
			activeItem.ownerEntityId(),
			self:aimVector(inaccuracy or self.inaccuracy),
			false,
			params
		)
  end
  return projectileId
end