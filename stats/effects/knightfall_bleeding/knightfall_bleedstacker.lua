function init()
  script.setUpdateDelta(5)
  
  self.currentStacks = config.getParameter("initialStackCount", 0)
  self.maxStacks = config.getParameter("maxStacks", 10)
  self.stackPerHit = config.getParameter("stackPerHit", 1)
  self.stackChanceValue = config.getParameter("stackChanceValue", 0.05)
  self.stackDuration = config.getParameter("stackDuration", 10)
  self.decayRate = config.getParameter("decayRate", 1)
  self.secondaryEffect = config.getParameter("secondaryEffect", nil)
  
  self.currentDuration = 0
  self.previousDuration = 0
  
  self.timer = self.stackDuration
end

function stackHandler()
  self.currentStacks = math.min(self.currentStacks + 1, self.maxStacks)

  local totalChance = self.currentStacks * self.stackChanceValue
  local roll = math.random()
  if roll <= totalChance and self.secondaryEffect then
    status.addEphemeralEffect(self.secondaryEffect)
  end
  
  local refresh = self.stackDuration * 0.25
  self.timer = math.min(self.timer + refresh, self.stackDuration)
end

function update(dt)
  self.timer = (self.timer or self.stackDuration) - dt
  
  self.currentDuration = effect.duration()
  if self.previousDuration < self.currentDuration then
    stackHandler()
  end
  self.previousDuration = effect.duration()

  if self.timer <= 0 then
    if self.currentStacks > 0 then
      self.currentStacks = self.currentStacks - 1
    end
    self.timer = self.stackDuration / math.max(self.decayRate, 1)
  end
  
  if self.currentStacks <= 0 then
	effect.expire()
	return
  end
end

function uninit()
end