--By Silver Sokolova

function init()
  knightfall_pendingQuestGiver = player.getProperty("knightfall_pendingRaidQuestGiver")
  if not storage.setPortraits then
    knightfall_updatePortraits()
  end

  message.setHandler("knightfall_raid:completeQuest", function()
    quest.complete()
  end)

  require(config.getParameter("originalScript"))
  setPortraits = function() end
  init()
  
  knightfall_originalQuestComplete = questComplete or function() end
  questComplete = function()
    knightfall_originalQuestComplete()
    local completedQuestGivers = player.getProperty("knightfall_completedRaidQuestGivers", {})
    completedQuestGivers[player.getProperty("knightfall_currentRaidQuestGiver", "")] = true
    player.setProperty("knightfall_currentRaidQuestGiver", "")
    player.setProperty("knightfall_completedRaidQuestGivers", completedQuestGivers)
--  sb.logInfo(sb.print(player.getProperty("knightfall_completedRaidQuestGivers", {})))
  end

  knightfall_originalQuestFail = questFail or function() end
  questFail = function()
    knightfall_originalQuestFail()
    player.setProperty("knightfall_currentRaidQuestGiver", "")
    player.setProperty("knightfall_raidCanTurnIn", nil)
  end

  knightfall_originalUpdate = update or function(...) end
  update = function(...)
    knightfall_originalUpdate(...)

    if knightfall_pendingQuestGiver and quest.state() ~= "Offer" then
      player.setProperty("knightfall_currentRaidQuestGiver", knightfall_pendingQuestGiver)
      player.setProperty("knightfall_pendingRaidQuestGiver", nil)
      knightfall_pendingQuestGiver = nil
    end
  end

  knightfall_turnIn = function()
    player.setProperty("knightfall_raidCanTurnIn", true)
    turnIn()
  end
  self.stages[3] = knightfall_turnIn
end

function knightfall_updatePortraits()
    local entityId = player.getProperty("knightfall_pendingRaidQuestGiverId"); if not entityId then return end
    local portrait = world.entityPortrait(entityId, "full")
    local name = world.entityName(entityId)

    for _, pType in pairs({"QuestStarted", "QuestComplete", "QuestFailed"}) do
      quest.setPortrait(pType, portrait)
      quest.setPortraitTitle(pType, name)
    end

    knightfall_pendingRaidQuestGiverId = nil
    storage.setPortraits = true
end
