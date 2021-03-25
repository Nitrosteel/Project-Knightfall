require "/scripts/vec2.lua"
require "/scripts/util.lua"

--[[--
  *
  * /items/active/effects/animchain.lua
  *
  * Replace the chain.lua animationScript with this (animchain.lua) to support animated beams.
  * Usage:
  * In the chain's startSegmentImage, segmentImage, and endSegmentImage, <beamFrame> will 
  *   be replaced by the frame number. For example:
  *
  *   "segmentImage" : "beam.png:beam.<beamFrame>" 
  *
  *   animchain will look for beam.1, beam.2, beam.3 and so on in the beam's frames file.
  *
  * JSON Parameters (under "chain" block):
  * - animFrames        - int:  how many frames does the animation have
  * - animInterval      - int:  how long (in in-game frames) does a single animation frame last
  * - reverseAnimation  - bool: whether to reverse the animation or not
  * 
  * 
  * Created by Lyrthras#7199 on 07/31/20
  * 
--]]--

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  self.frameCounter = (self.frameCounter or 0) + 1

  self.chains = animationConfig.animationParameter("chains") or {}
  for _, chain in pairs(self.chains) do
    -- calculate current frame
    if self.frameCounter > (chain.animFrames or 1) * (chain.animInterval or 1) then
      self.frameCounter = 1
    end
    local currentFrame = math.ceil(self.frameCounter / (chain.animInterval or 1))
    if chain.reverseAnimation then
      currentFrame = (chain.animFrames or 1) - currentFrame + 1
    end

    local continue = false
    if chain.targetEntityId then
      if world.entityExists(chain.targetEntityId) then
        chain.endPosition = world.entityPosition(chain.targetEntityId)
      end
    end
    if chain.sourcePart then
      local beamSource = animationConfig.partPoint(chain.sourcePart, "beamSource")
      if beamSource then
        chain.startPosition = vec2.add(entity.position(), beamSource)
      else
        continue = true
      end
    end
    if chain.endPart then
      local beamEnd = animationConfig.partPoint(chain.endPart, "beamEnd")
      if beamEnd then
        chain.endPosition = vec2.add(entity.position(), beamEnd)
      else
        continue = true
      end
    end

    if not continue and (not chain.targetEntityId or world.entityExists(chain.targetEntityId)) then
      -- sb.logInfo("Building drawables for chain %s", chain)
      local startPosition = chain.startPosition or vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(chain.startOffset))
      local endPosition = chain.endPosition or vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(chain.endOffset))

      if chain.maxLength then
        endPosition = vec2.add(startPosition, vec2.mul(vec2.norm(world.distance(endPosition, startPosition)), chain.maxLength))
      end

      if chain.testCollision then
        local angle = vec2.angle(world.distance(endPosition, startPosition))
        -- lines starting on tile boundaries will collide with the tile
        -- work around this by starting the collision check a small distance along the line from the actual start position
        local collisionStart = vec2.add(startPosition, vec2.withAngle(angle, 0.01))
        local collision = world.lineTileCollisionPoint(startPosition, endPosition)
        if collision then
          local collidePosition, normal = collision[1], collision[2]
          if chain.bounces and chain.bounces > 0 then
            local length = world.magnitude(endPosition, startPosition) - world.magnitude(collidePosition, startPosition)
            local newChain = copy(chain)
            newChain.sourcePart, newChain.endPart, newChain.targetEntityId = nil, nil, nil
            newChain.startPosition = collidePosition
            newChain.endPosition = vec2.add(collidePosition, vec2.mul(vec2.withAngle(angle, length), normal[1] == 0 and {1, -1} or {-1, 1}))
            newChain.bounces = chain.bounces - 1
            table.insert(self.chains, newChain)
          end

          endPosition = collidePosition
        end
      end

      local chainVec = world.distance(endPosition, startPosition)
      local chainDirection = chainVec[1] < 0 and -1 or 1
      local chainLength = vec2.mag(chainVec)

      local arcAngle = 0
      if chain.arcRadius then
        arcAngle = chainDirection * 2 * math.asin(chainLength / (2 * chain.arcRadius))
        chainLength = chainDirection * arcAngle * chain.arcRadius
      end

      local segmentCount = math.floor(((chainLength + (chain.overdrawLength or 0)) / chain.segmentSize) + 0.5)
      if segmentCount > 0 then
        local chainStartAngle = vec2.angle(chainVec) - arcAngle / 2
        if chainVec[1] < 0 then chainStartAngle = math.pi - chainStartAngle end

        local segmentOffset = vec2.mul(vec2.norm(chainVec), chain.segmentSize)
        segmentOffset = vec2.rotate(segmentOffset, -arcAngle / 2)
        local currentBaseOffset = vec2.add(startPosition, vec2.mul(segmentOffset, 0.5))
        local lastDrawnSegment = chain.drawPercentage and math.ceil(segmentCount * chain.drawPercentage) or segmentCount
        for i = 1, lastDrawnSegment do
          local image = chain.segmentImage
          if i == 1 and chain.startSegmentImage then
            image = chain.startSegmentImage
          elseif i == lastDrawnSegment and chain.endSegmentImage then
            image = chain.endSegmentImage
          end

          -- apply frame to image
          image = image:gsub("<beamFrame>", currentFrame)

          -- taper applies evenly from full size at the start to (1.0 - chain.taper) size at the end
          if chain.taper then
            local taperFactor = 1 - ((i - 1) / lastDrawnSegment) * chain.taper
            image = image .. "?scale=1.0=" .. util.round(taperFactor, 1)
          end

          -- per-segment offsets (jitter, waveform, etc)
          local thisOffset = {0, 0}
          if chain.jitter then
            thisOffset = vec2.add(thisOffset, {0, (math.random() - 0.5) * chain.jitter})
          end
          if chain.waveform then
            local angle = ((i * chain.segmentSize) - (os.clock() * (chain.waveform.movement or 0))) / (chain.waveform.frequency / math.pi)
            local sineVal = math.sin(angle) * chain.waveform.amplitude * 0.5
            thisOffset = vec2.add(thisOffset, {0, sineVal})
          end

          local segmentAngle = chainStartAngle + (i - 1) * chainDirection * (arcAngle / segmentCount)

          thisOffset = vec2.rotate(thisOffset, chainVec[1] >= 0 and segmentAngle or -segmentAngle)

          local segmentPos = vec2.add(currentBaseOffset, thisOffset)
          local drawable = {
            image = image,
            centered = true,
            mirrored = chainVec[1] < 0,
            rotation = segmentAngle,
            position = segmentPos,
            fullbright = chain.fullbright or false
          }

          localAnimator.addDrawable(drawable, chain.renderLayer)
          if chain.light then
            localAnimator.addLightSource({
              position = segmentPos,
              color = chain.light,
            })
          end

          segmentOffset = vec2.rotate(segmentOffset, arcAngle / segmentCount)
          currentBaseOffset = vec2.add(currentBaseOffset, segmentOffset)
        end
      end
    end
  end
end
