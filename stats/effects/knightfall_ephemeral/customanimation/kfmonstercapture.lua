function init()
  self.colorFadeDuration = config.getParameter("colorFadeDuration")
  self.alphaFadeDuration = config.getParameter("alphaFadeDuration")
  self.fadeMax = config.getParameter("fadeMax")
  self.color = config.getParameter("fadeColor")
  self.elapsed = 0
  mcontroller.setVelocity({0, 0})
  status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  animator.burstParticleEmitter("captureParticles")
  animator.playSound("capture")
end

function update(dt)
  self.elapsed = self.elapsed + dt
  if self.elapsed < self.colorFadeDuration then
    local fade = (self.elapsed / self.colorFadeDuration) * self.fadeMax
    effect.setParentDirectives(string.format("fade=000000=%.1f", fade))
  else
    local alphaDuration = self.alphaFadeDuration - self.colorFadeDuration
    local alphaElapsed = self.elapsed - self.colorFadeDuration
    local alpha = math.max(math.floor((alphaElapsed / alphaDuration) * 255), 0)
    effect.setParentDirectives(string.format("?multiply=ffffff%02x?fade=ff0000=%.1f", alpha, self.fadeMax))
    mcontroller.controlModifiers({
        facingSuppressed = true,
        movementSuppressed = true
      })
  end
end

function uninit()
end
