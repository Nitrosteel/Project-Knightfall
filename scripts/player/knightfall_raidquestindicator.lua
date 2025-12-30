--By Silver Sokolova

local originalInit = init or function() end
local originalUpdate = update or function(...) end

function init(); originalInit()
  knightfallRaid_completedQuestGivers = player.getProperty("knightfall_completedRaidQuestGivers", {})
  knightfallRaid_currentQuestGiver = player.getProperty("knightfall_currentRaidQuestGiver", "")
  lastKnightfallRaid_currentQuestGiver = knightfallRaid_currentQuestGiver

  message.setHandler("knightfall_raidquestprompt", function(_, _, uniqueId, entityId, quest)
    local completedQuestGivers = player.getProperty("knightfall_completedRaidQuestGivers", {})
    local currentQuestGiver = player.getProperty("knightfall_currentRaidQuestGiver", "")

    if uniqueId ~= currentQuestGiver and not completedQuestGivers[uniqueId] then
      player.setProperty("knightfall_pendingRaidQuestGiver", uniqueId)
      player.setProperty("knightfall_pendingRaidQuestGiverId", entityId)
      player.startQuest(quest)
    elseif uniqueId == currentQuestGiver and player.getProperty("knightfall_raidCanTurnIn") then
      world.sendEntityMessage(player.id(), "knightfall_raid:completeQuest")
    end
  end)
end

function update(...); originalUpdate(...)
  knightfallRaid_currentQuestGiver = player.getProperty("knightfall_currentRaidQuestGiver", "")

  if lastKnightfallRaid_currentQuestGiver ~= knightfallRaid_currentQuestGiver then
    knightfallRaid_completedQuestGivers = player.getProperty("knightfall_completedRaidQuestGivers", {})
    lastKnightfallRaid_currentQuestGiver = knightfallRaid_currentQuestGiver
    player.setProperty("knightfall_raidCanTurnIn", nil)
  end
  
  local pos = entity.position()
  local entities = world.npcQuery(pos, 60)

  for _, id in pairs(entities) do
    if world.entityTypeName(id) == "knightfall_knightcommander" and knightfallRaid_currentQuestGiver then
      local uniqueId = world.entityUniqueId(id)
      if uniqueId then
        local ePos = world.entityPosition(id)
        if (not knightfallRaid_completedQuestGivers[uniqueId]) and (knightfallRaid_currentQuestGiver ~= uniqueId) then
          knightfallRaid_displayQuestIndicator("/interface/quests/questgiver.png", {ePos[1] - pos[1], ePos[2] - pos[2] + 2.75})
        elseif knightfallRaid_currentQuestGiver == uniqueId and player.getProperty("knightfall_raidCanTurnIn") then
          knightfallRaid_displayQuestIndicator("/interface/quests/questreceiver.png", {ePos[1] - pos[1], ePos[2] - pos[2] + 2.75})
        end
      end
    end
  end
end

function knightfallRaid_displayQuestIndicator(image, position)
  localAnimator.addDrawable({
    image = image,
    fullbright = true,
    position = position
  }, "Overlay")
end
