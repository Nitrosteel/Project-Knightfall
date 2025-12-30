--By Silver Sokolova

require "/scripts/actions/dialog.lua"

function init()
  npc.setInteractive(true)
  if not entity.uniqueId() then
    npc.setUniqueId(sb.makeUuid())
  end
  knightfall_questToGive = config.getParameter("quest")
end

function interact(args)
  mcontroller.controlFace(args.sourcePosition[1] > mcontroller.xPosition() and 1 or -1)

  world.sendEntityMessage(args.sourceId, "knightfall_raidquestprompt", entity.uniqueId(), entity.id(), knightfall_questToGive)

  sayToEntity({
    dialogType = "dialog.converse",
    dialog = nil,
    entity = args.sourceId,
    tags = {}
  })
end
