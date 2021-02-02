function init()
  effect.setParentDirectives("?multiply=ffffff00")
  self.invisibilityDuration = config.getParameter("invisibilityDuration")
  self.fadeMax = config.getParameter("fadeMax")
  self.duration = effect.duration()
  self.elapsed = 0
  self.color = config.getParameter("fadeColor")
  status.setResource("stunned", math.max(status.resource("stunned"), self.invisibilityDuration))
end

function update(dt)
  self.elapsed = self.elapsed + dt

  if self.elapsed >= self.invisibilityDuration then
    if not self.playedSound then
      animator.burstParticleEmitter("releaseParticles")
      animator.playSound("release")
      self.playedSound = true
    end

    local visibleDuration = self.duration - self.invisibilityDuration
    local elapsedVisible = self.elapsed - self.invisibilityDuration
    local fade = (1.0 - elapsedVisible / visibleDuration) * self.fadeMax
    effect.setParentDirectives("fade="..self.color.."="..fade)

  else
    effect.setParentDirectives(string.format("?multiply=ffffff%02x?fade=%s=%.1f", math.floor(self.elapsed / self.invisibilityDuration * 255), self.color, self.fadeMax))
    mcontroller.controlModifiers({
        facingSuppressed = true,
        movementSuppressed = true
      })
  end
end

function uninit()
end
