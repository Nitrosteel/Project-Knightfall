--By Silver Sokolova

require "/scripts/actions/dialog.lua"

function init()
  npc.setInteractive(true)
  if not entity.uniqueId() then
    npc.setUniqueId(sb.makeUuid())
  end
  local quests = config.getParameter("quests")
  storage.knightfall_questToGive = quests[math.random(#quests)]
end

function interact(args)
  mcontroller.controlFace(args.sourcePosition[1] > mcontroller.xPosition() and 1 or -1)

  world.sendEntityMessage(args.sourceId, "knightfall_raidquestprompt", entity.uniqueId(), entity.id(), storage.knightfall_questToGive)

  sayToEntity({
    dialogType = "dialog.converse",
    dialog = nil,
    entity = args.sourceId,
    tags = {}
  })
end
