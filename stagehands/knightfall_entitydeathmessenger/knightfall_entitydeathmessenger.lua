function init()
  entityIds = config.getParameter("entityIds", {})
  messages = config.getParameter("messages", {})
end

function update(dt)
  if not alive then
    alive = aliveCount()
    lastAlive = alive
  end
  
  if alive > 0 then
    local p = stagehand.position()
    world.loadRegion({p[1], p[2], p[1], p[2]})
    
    alive = aliveCount()
    
    if alive < lastAlive then
      local sent = 0
      
      for _,m in pairs(messages) do
        if m.sent then
          sent = sent + 1
        else
          local req = m.alive or 0
          
          if req < lastAlive and req >= alive then
            sendMessage(table.unpack(m.args))
            m.sent = true
          end
        end
      end
      
      if sent == #messages then
        stagehand.die()
      end
      
      lastAlive = alive
    end
  else
  --stagehand.die() --silver disabled this in the middle of the night to see if it would fix the thing
  end
end

function aliveCount()
  local a = 0
  for _,id in pairs(entityIds) do
    if world.loadUniqueEntity(id) ~= 0 then
      a = a + 1
    end
  end
  return a
end

function sendMessage(...)
  for _,id in pairs(world.players()) do
    world.sendEntityMessage(id, ...)
  end
end