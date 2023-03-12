-- Copyright (C) 2022  veden

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.


if SquadG then
    return SquadG
end
local Squad = {}

--

local Universe

-- imports

local Constants = require("Constants")
local MapUtils = require("MapUtils")
local BaseUtils = require("BaseUtils")
local MathUtils = require("MathUtils")
local ChunkPropertyUtils = require("ChunkPropertyUtils")
local Utils = require("Utils")

-- Constants

local BASE_AI_STATE_ONSLAUGHT = Constants.BASE_AI_STATE_ONSLAUGHT
local BASE_AI_STATE_RAIDING = Constants.BASE_AI_STATE_RAIDING
local MAGIC_MAXIMUM_NUMBER = Constants.MAGIC_MAXIMUM_NUMBER
local MINIMUM_EXPANSION_DISTANCE = Constants.MINIMUM_EXPANSION_DISTANCE
local PLAYER_PHEROMONE_GENERATOR_THRESHOLD = Constants.PLAYER_PHEROMONE_GENERATOR_THRESHOLD
local COMMAND_TIMEOUT = Constants.COMMAND_TIMEOUT
local PLAYER_PHEROMONE = Constants.PLAYER_PHEROMONE
local BASE_PHEROMONE = Constants.BASE_PHEROMONE
local ENEMY_PHEROMONE = Constants.ENEMY_PHEROMONE
local RESOURCE_PHEROMONE = Constants.RESOURCE_PHEROMONE

local FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT = Constants.FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT

local SQUAD_BUILDING = Constants.SQUAD_BUILDING

local SQUAD_RAIDING = Constants.SQUAD_RAIDING
local SQUAD_SETTLING = Constants.SQUAD_SETTLING
local SQUAD_GUARDING = Constants.SQUAD_GUARDING
local SQUAD_RETREATING = Constants.SQUAD_RETREATING

local BASE_AI_STATE_SIEGE = Constants.BASE_AI_STATE_SIEGE
local BASE_AI_STATE_AGGRESSIVE = Constants.BASE_AI_STATE_AGGRESSIVE

local PLAYER_PHEROMONE_MULTIPLER = Constants.PLAYER_PHEROMONE_MULTIPLER

local DEFINES_DISTRACTION_NONE = defines.distraction.none
local DEFINES_DISTRACTION_BY_ENEMY = defines.distraction.by_enemy
local DEFINES_DISTRACTION_BY_ANYTHING = defines.distraction.by_anything
local COOLDOWN_RETREAT = Constants.COOLDOWN_RETREAT

local CHUNK_SIZE = Constants.CHUNK_SIZE
local COOLDOWN_RALLY = Constants.COOLDOWN_RALLY
local RALLY_CRY_DISTANCE = Constants.RALLY_CRY_DISTANCE

local AI_SQUAD_COST = Constants.AI_SQUAD_COST
local AI_SETTLER_COST = Constants.AI_SETTLER_COST
local AI_VENGENCE_SQUAD_COST = Constants.AI_VENGENCE_SQUAD_COST
local AI_VENGENCE_SETTLER_COST = Constants.AI_VENGENCE_SETTLER_COST
local CHUNK_ALL_DIRECTIONS = Constants.CHUNK_ALL_DIRECTIONS

-- imported functions

local getPassable = ChunkPropertyUtils.getPassable
local getRallyTick = ChunkPropertyUtils.getRallyTick
local setRallyTick = ChunkPropertyUtils.setRallyTick
local positionFromDirectionAndChunk = MapUtils.positionFromDirectionAndChunk
local modifyBaseUnitPoints = BaseUtils.modifyBaseUnitPoints

local tableRemove = table.remove
local tableInsert = table.insert
local mCeil = math.ceil

local isActiveNest = ChunkPropertyUtils.isActiveNest
local isActiveRaidNest = ChunkPropertyUtils.isActiveRaidNest

local gaussianRandomRangeRG = MathUtils.gaussianRandomRangeRG
local getEnemyStructureCount = ChunkPropertyUtils.getEnemyStructureCount
local getRetreatTick = ChunkPropertyUtils.getRetreatTick

local findNearbyBase = ChunkPropertyUtils.findNearbyBase
local tableSize = table_size
local setPositionInCommand = Utils.setPositionInCommand

local euclideanDistancePoints = MathUtils.euclideanDistancePoints
local canMoveChunkDirection = MapUtils.canMoveChunkDirection

local setRetreatTick = ChunkPropertyUtils.setRetreatTick

local removeSquadFromChunk = ChunkPropertyUtils.removeSquadFromChunk
local addDeathGenerator = ChunkPropertyUtils.addDeathGenerator

local getNeighborChunks = MapUtils.getNeighborChunks
local addSquadToChunk = ChunkPropertyUtils.addSquadToChunk
local getChunkByXY = MapUtils.getChunkByXY
local positionToChunkXY = MapUtils.positionToChunkXY
local positionFromDirectionAndFlat = MapUtils.positionFromDirectionAndFlat

local euclideanDistanceNamed = MathUtils.euclideanDistanceNamed

-- module code
local function scoreRetreatLocation(neighborChunk)
    return (-neighborChunk[BASE_PHEROMONE] +
            -(neighborChunk[PLAYER_PHEROMONE] * PLAYER_PHEROMONE_MULTIPLER) +
            -((neighborChunk.playerBaseGenerator or 0) * 1000))
end

local function scoreResourceLocation(neighborChunk)
    return neighborChunk[RESOURCE_PHEROMONE]
        - (neighborChunk[PLAYER_PHEROMONE] * PLAYER_PHEROMONE_MULTIPLER)
        - neighborChunk[ENEMY_PHEROMONE]
end

local function scoreSiegeLocation(neighborChunk)
    local settle = neighborChunk[BASE_PHEROMONE]
        + neighborChunk[RESOURCE_PHEROMONE] * 0.5
        + (neighborChunk[PLAYER_PHEROMONE] * PLAYER_PHEROMONE_MULTIPLER)

    return settle - neighborChunk[ENEMY_PHEROMONE]
end

local function scoreAttackLocation(neighborChunk)
    local damage = neighborChunk[BASE_PHEROMONE] +
        (neighborChunk[PLAYER_PHEROMONE] * PLAYER_PHEROMONE_MULTIPLER)
    return damage
end

local function findMovementPosition(surface, position)
    return surface.find_non_colliding_position(
        "behemoth-biter",
        position,
        10,
        2,
        false
    )
end

local function findDeploymentPosition(surface, position)
    return surface.find_non_colliding_position(
        "biter-spawner",
        position,
        CHUNK_SIZE,
        4,
        true
    )
end

local function calculateSettlerMaxDistance()
    local targetDistance
    local distanceRoll = Universe.random()
    if distanceRoll < 0.05 then
        return 0
    elseif distanceRoll < 0.30 then
        targetDistance = Universe.expansionLowTargetDistance
    elseif distanceRoll < 0.70 then
        targetDistance = Universe.expansionMediumTargetDistance
    elseif distanceRoll < 0.95 then
        targetDistance = Universe.expansionHighTargetDistance
    else
        return Universe.expansionMaxDistance
    end
    return gaussianRandomRangeRG(targetDistance,
                                 Universe.expansionDistanceDeviation,
                                 MINIMUM_EXPANSION_DISTANCE,
                                 Universe.expansionMaxDistance,
                                 Universe.random)
end

local function addMovementPenalty(squad, chunk)
    if (chunk == -1) then
        return
    end
    local penalties = squad.penalties
    local penaltyCount = #penalties
    for i=1,penaltyCount do
        local penalty = penalties[i]
        if (penalty.c.id == chunk.id) then
            penalty.v = penalty.v + 1
            if penalty.v >= 15 then
                if Universe.enabledMigration and
                    (Universe.builderCount < Universe.AI_MAX_BUILDER_COUNT) then
                    squad.settler = true
                    squad.originPosition.x = squad.group.position.x
                    squad.originPosition.y = squad.group.position.y
                    squad.maxDistance = calculateSettlerMaxDistance()

                    squad.status = SQUAD_SETTLING
                else
                    squad.group.destroy()
                end
            end
            return
        end
    end
    if (penaltyCount == 10) then
        tableRemove(penalties, 10)
    end
    tableInsert(penalties,
                1,
                { v = 1,
                  c = chunk })
end

--[[
    Expects all neighbors adjacent to a chunk
--]]
local function scoreNeighborsForSettling(map, chunk, neighborDirectionChunks, scoreFunction)
    local highestChunk = -1
    local highestScore = -MAGIC_MAXIMUM_NUMBER
    local highestDirection = 0

    for x=1,8 do
        local neighborChunk = neighborDirectionChunks[x]
        if (neighborChunk ~= -1) then
            if (chunk == -1) or canMoveChunkDirection(x, chunk, neighborChunk) then
                local score = scoreFunction(neighborChunk)
                if (score > highestScore) then
                    highestScore = score
                    highestChunk = neighborChunk
                    highestDirection = x
                end
            end
        end
    end

    if (chunk ~= -1) and (scoreFunction(chunk) > highestScore) then
        return chunk, 0, -1, 0
    end

    local nextHighestChunk = -1
    local nextHighestScore = highestScore
    local nextHighestDirection = 0

    if (highestChunk ~= -1) then
        neighborDirectionChunks = getNeighborChunks(map, highestChunk.x, highestChunk.y)
        for x=1,8 do
            local neighborChunk = neighborDirectionChunks[x]
            if ((neighborChunk ~= -1) and ((chunk == -1) or (neighborChunk.id ~= chunk.id)) and
                canMoveChunkDirection(x, highestChunk, neighborChunk)) then
                local score = scoreFunction(neighborChunk)
                if (score > nextHighestScore) then
                    nextHighestScore = score
                    nextHighestChunk = neighborChunk
                    nextHighestDirection = x
                end
            end
        end
    end

    return highestChunk, highestDirection, nextHighestChunk, nextHighestDirection
end

local function settleMove(map, squad)
    local group = squad.group
    local targetPosition = {x=0,y=0}

    local groupPosition = group.position
    local x, y = positionToChunkXY(groupPosition)
    local chunk = getChunkByXY(map, x, y)
    local scoreFunction = scoreResourceLocation
    if (squad.type == BASE_AI_STATE_SIEGE) then
        scoreFunction = scoreSiegeLocation
    end
    local squadChunk = squad.chunk
    if squadChunk ~= -1 then
        addDeathGenerator(squadChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
    end
    if chunk ~= -1 then
        addSquadToChunk(chunk, squad)
        addMovementPenalty(squad, chunk)
        if not squad.group.valid then
            return
        end
    end
    local distance = euclideanDistancePoints(groupPosition.x,
                                             groupPosition.y,
                                             squad.originPosition.x,
                                             squad.originPosition.y)
    local cmd
    local position
    local surface = map.surface

    if (chunk ~= -1) and
        (
            (distance >= squad.maxDistance) or
            (
                chunk.resourceGenerator and (not chunk.nestCount) and (not chunk.hiveCount)
            )
        )
    then
        position = findMovementPosition(surface, groupPosition)

        if not position then
            position = groupPosition
        end

        cmd = Universe.settleCommand
        if squad.kamikaze then
            cmd.distraction = DEFINES_DISTRACTION_NONE
        else
            cmd.distraction = DEFINES_DISTRACTION_BY_ENEMY
        end

        setPositionInCommand(cmd, position)

        squad.status = SQUAD_BUILDING

        group.set_command(cmd)
    else
        local attackChunk,
            attackDirection,
            nextAttackChunk,
            nextAttackDirection = scoreNeighborsForSettling(map,
                                                            chunk,
                                                            getNeighborChunks(map, x, y),
                                                            scoreFunction)

        if (attackChunk == -1) then
            cmd = Universe.wanderCommand
            group.set_command(cmd)
            return
        elseif (attackDirection ~= 0) then
            local attackPlayerThreshold = Universe.attackPlayerThreshold

            if (nextAttackChunk ~= -1) then
                if (not nextAttackChunk.playerBaseGenerator)
                    and ((nextAttackChunk.playerGenerator or 0) < PLAYER_PHEROMONE_GENERATOR_THRESHOLD)
                then
                    attackChunk = nextAttackChunk
                    position = findMovementPosition(
                        surface,
                        positionFromDirectionAndFlat(
                            nextAttackDirection,
                            positionFromDirectionAndFlat(
                                attackDirection,
                                groupPosition
                            )
                        )
                    )
                else
                    position = groupPosition
                end
            else
                position = findMovementPosition(
                    surface,
                    positionFromDirectionAndFlat(
                        attackDirection,
                        groupPosition
                    )
                )
            end

            if position then
                targetPosition.x = position.x
                targetPosition.y = position.y
                if nextAttackChunk ~= -1 then
                    addDeathGenerator(nextAttackChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
                else
                    addDeathGenerator(attackChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
                end
            else
                cmd = Universe.wanderCommand
                group.set_command(cmd)
                return
            end

            if (nextAttackChunk ~= -1)
                and (
                    nextAttackChunk.playerBaseGenerator
                    or ((nextAttackChunk.playerBaseGenerator or 0) >= PLAYER_PHEROMONE_GENERATOR_THRESHOLD)
                )
            then
                cmd = Universe.settleCommand
                squad.status = SQUAD_BUILDING
                if squad.kamikaze then
                    cmd.distraction = DEFINES_DISTRACTION_NONE
                else
                    cmd.distraction = DEFINES_DISTRACTION_BY_ENEMY
                end
            elseif attackChunk.playerBaseGenerator
                or (attackChunk[PLAYER_PHEROMONE] >= attackPlayerThreshold)
            then
                cmd = Universe.attackCommand

                if not squad.rabid then
                    squad.frenzy = true
                    squad.frenzyPosition.x = groupPosition.x
                    squad.frenzyPosition.y = groupPosition.y
                end
            else
                cmd = Universe.moveCommand
                if squad.rabid or squad.kamikaze then
                    cmd.distraction = DEFINES_DISTRACTION_NONE
                else
                    cmd.distraction = DEFINES_DISTRACTION_BY_ENEMY
                end
            end
        else
            cmd = Universe.settleCommand
            targetPosition.x = groupPosition.x
            targetPosition.y = groupPosition.y

            if squad.kamikaze then
                cmd.distraction = DEFINES_DISTRACTION_NONE
            else
                cmd.distraction = DEFINES_DISTRACTION_BY_ENEMY
            end

            squad.status = SQUAD_BUILDING
        end

        setPositionInCommand(cmd, targetPosition)

        group.set_command(cmd)
    end
end

--[[
    Expects all neighbors adjacent to a chunk
--]]
local function scoreNeighborsForAttack(map, chunk, neighborDirectionChunks, scoreFunction)
    local highestChunk = -1
    local highestScore = -MAGIC_MAXIMUM_NUMBER
    local highestDirection

    for x=1,8 do
        local neighborChunk = neighborDirectionChunks[x]
        if (neighborChunk ~= -1) then
            if (chunk == -1) or canMoveChunkDirection(x, chunk, neighborChunk) then
                local score = scoreFunction(neighborChunk)
                if (score > highestScore) then
                    highestScore = score
                    highestChunk = neighborChunk
                    highestDirection = x
                end
            end
        end
    end

    local nextHighestChunk = -1
    local nextHighestScore = highestScore
    local nextHighestDirection

    if (highestChunk ~= -1) then
        neighborDirectionChunks = getNeighborChunks(map, highestChunk.x, highestChunk.y)
        for x=1,8 do
            local neighborChunk = neighborDirectionChunks[x]
            if ((neighborChunk ~= -1) and ((chunk == -1) or (neighborChunk.id ~= chunk.id)) and
                canMoveChunkDirection(x, highestChunk, neighborChunk)) then
                local score = scoreFunction(neighborChunk)
                if (score > nextHighestScore) then
                    nextHighestScore = score
                    nextHighestChunk = neighborChunk
                    nextHighestDirection = x
                end
            end
        end
    end

    return highestChunk, highestDirection, nextHighestChunk, nextHighestDirection
end

local function attackMove(map, squad)
    local targetPosition = {0,0}

    local group = squad.group

    local surface = map.surface
    local position
    local groupPosition = group.position
    local x, y = positionToChunkXY(groupPosition)
    local chunk = getChunkByXY(map, x, y)
    local attackScorer = scoreAttackLocation
    local squadChunk = squad.chunk
    if squadChunk ~= -1 then
        addDeathGenerator(squadChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
    end
    if chunk ~= -1 then
        addSquadToChunk(chunk, squad)
        addMovementPenalty(squad, chunk)
        if not squad.group.valid then
            return
        end
    end
    squad.frenzy = (squad.frenzy and (euclideanDistanceNamed(groupPosition, squad.frenzyPosition) < 100))
    local attackChunk, attackDirection,
        nextAttackChunk, nextAttackDirection = scoreNeighborsForAttack(map,
                                                                       chunk,
                                                                       getNeighborChunks(map, x, y),
                                                                       attackScorer)
    local cmd
    if (attackChunk == -1) then
        cmd = Universe.wanderCommand
        group.set_command(cmd)
        return
    end

    if (nextAttackChunk ~= -1) then
        attackChunk = nextAttackChunk
        position = findMovementPosition(
            surface,
            positionFromDirectionAndFlat(
                nextAttackDirection,
                positionFromDirectionAndFlat(
                    attackDirection,
                    groupPosition
                )
            )
        )
    else
        position = findMovementPosition(
            surface,
            positionFromDirectionAndFlat(
                attackDirection,
                groupPosition
            )
        )
    end

    if not position then
        cmd = Universe.wanderCommand
        group.set_command(cmd)
        return
    else
        targetPosition.x = position.x
        targetPosition.y = position.y
        if (nextAttackChunk ~= -1) then
            addDeathGenerator(nextAttackChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
        else
            addDeathGenerator(attackChunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
        end
    end

    if attackChunk.playerBaseGenerator and
        (attackChunk[PLAYER_PHEROMONE] >= Universe.attackPlayerThreshold)
    then
        cmd = Universe.attackCommand

        if not squad.rabid then
            squad.frenzy = true
            squad.frenzyPosition.x = groupPosition.x
            squad.frenzyPosition.y = groupPosition.y
        end
    else
        cmd = Universe.moveCommand
        if squad.rabid or squad.frenzy then
            cmd.distraction = DEFINES_DISTRACTION_BY_ANYTHING
        else
            cmd.distraction = DEFINES_DISTRACTION_BY_ENEMY
        end
    end
    setPositionInCommand(cmd, targetPosition)

    group.set_command(cmd)
end

local function buildMove(map, squad)
    local group = squad.group
    local groupPosition = group.position
    local newGroupPosition = findMovementPosition(map.surface, groupPosition)

    if not newGroupPosition then
        setPositionInCommand(Universe.settleCommand, groupPosition)
    else
        setPositionInCommand(Universe.settleCommand, newGroupPosition)
    end

    group.set_command(Universe.compoundSettleCommand)
end

function Squad.cleanSquads(tick)
    local squads = Universe.groupNumberToSquad
    local groupId = Universe.squadIterator
    local squad
    if not groupId then
        groupId, squad = next(squads, groupId)
    else
        squad = squads[groupId]
    end
    if not groupId then
        Universe.squadIterator = nil
        if (tableSize(squads) == 0) then
            -- this is needed as the next command remembers the max length a table has been
            Universe.groupNumberToSquad = {}
        end
    else
        Universe.squadIterator = next(squads, groupId)
        local group = squad.group
        if not group.valid then
            if squad.chunk ~= -1 then
                addDeathGenerator(squad.chunk, -FIVE_DEATH_PHEROMONE_GENERATOR_AMOUNT)
            end
            removeSquadFromChunk(squad)
            if squad.settlers then
                Universe.builderCount = Universe.builderCount - 1
                if Universe.builderCount < 0 then
                    Universe.builderCount = 0
                end
            else
                Universe.squadCount = Universe.squadCount - 1
                if Universe.squadCount < 0 then
                    Universe.squadCount = 0
                end
                if squad.type == BASE_AI_STATE_AGGRESSIVE then
                    local base = squad.base
                    base.sentAggressiveGroups = base.sentAggressiveGroups - 1
                    if base.sentAggressiveGroups < 0 then
                        base.sentAggressiveGroups = 0
                    end
                end
            end
            squads[groupId] = nil
        elseif (group.state == 4) then
            squad.wanders = 0
            Squad.squadDispatch(squad.map, squad, tick)
        elseif (squad.commandTick and (squad.commandTick < tick)) then
            if squad.wanders > 5 then
                squad.group.destroy()
            else
                squad.wanders = squad.wanders + 1
                local cmd = Universe.wander2Command
                squad.commandTick = tick + COMMAND_TIMEOUT
                group.set_command(cmd)
                group.start_moving()
            end
        end
    end
end

function Squad.squadDispatch(map, squad, tick)
    local group = squad.group
    if group and group.valid then
        local status = squad.status
        if (status == SQUAD_RAIDING) then
            squad.commandTick = tick + COMMAND_TIMEOUT
            attackMove(map, squad)
        elseif (status == SQUAD_SETTLING) then
            squad.commandTick = tick + COMMAND_TIMEOUT
            settleMove(map, squad)
        elseif (status == SQUAD_RETREATING) then
            squad.commandTick = tick + COMMAND_TIMEOUT
            if squad.settlers then
                squad.status = SQUAD_SETTLING
                settleMove(map, squad)
            else
                squad.status = SQUAD_RAIDING
                attackMove(map, squad)
            end
        elseif (status == SQUAD_BUILDING) then
            squad.commandTick = tick + COMMAND_TIMEOUT
            removeSquadFromChunk(squad)
            buildMove(map, squad)
        elseif (status == SQUAD_GUARDING) then
            squad.commandTick = tick + COMMAND_TIMEOUT
            if squad.settlers then
                squad.status = SQUAD_SETTLING
                settleMove(map, squad)
            else
                squad.status = SQUAD_RAIDING
                attackMove(map, squad)
            end
        end
    end
end

--[[
    Expects all neighbors adjacent to a chunk
--]]
local function scoreNeighborsForRetreat(chunk, neighborDirectionChunks, scoreFunction, map)
    local highestChunk = -1
    local highestScore = -MAGIC_MAXIMUM_NUMBER
    local highestDirection

    for x=1,8 do
        local neighborChunk = neighborDirectionChunks[x]
        if (neighborChunk ~= -1) then
            if (chunk == -1) or canMoveChunkDirection(x, chunk, neighborChunk) then
                local score = scoreFunction(neighborChunk)
                if (score > highestScore) then
                    highestScore = score
                    highestChunk = neighborChunk
                    highestDirection = x
                end
            end
        end
    end

    local nextHighestChunk = -1
    local nextHighestScore = highestScore
    local nextHighestDirection

    if (highestChunk ~= -1) then
        neighborDirectionChunks = getNeighborChunks(map, highestChunk.x, highestChunk.y)
        for x=1,8 do
            local neighborChunk = neighborDirectionChunks[x]

            if ((neighborChunk ~= -1) and ((chunk == -1) or (neighborChunk.id ~= chunk.id)) and
                canMoveChunkDirection(x, highestChunk, neighborChunk)) then
                local score = scoreFunction(neighborChunk)
                if (score > nextHighestScore) then
                    nextHighestScore = score
                    nextHighestChunk = neighborChunk
                    nextHighestDirection = x
                end
            end
        end
    end

    if (nextHighestChunk == nil) then
        nextHighestChunk = -1
    end

    return highestChunk, highestDirection, nextHighestChunk, nextHighestDirection
end

local function findNearbyRetreatingSquad(map, chunk)
    if chunk.squads then
        for _,squad in pairs(chunk.squads) do
            local unitGroup = squad.group
            if (squad.status == SQUAD_RETREATING) and unitGroup and unitGroup.valid then
                return squad
            end
        end
    end

    local neighbors = getNeighborChunks(map, chunk.x, chunk.y)

    for i=1,#neighbors do
        local neighbor = neighbors[i]
        if (neighbor ~= -1) and neighbor.squads then
            for _,squad in pairs(neighbor.squads) do
                local unitGroup = squad.group
                if (squad.status == SQUAD_RETREATING) and unitGroup and unitGroup.valid then
                    return squad
                end
            end
        end
    end
    return nil
end

function Squad.retreatUnits(chunk, cause, map, tick, radius)
    if (tick - getRetreatTick(chunk) > COOLDOWN_RETREAT) and (getEnemyStructureCount(chunk) == 0) then

        setRetreatTick(chunk, tick)
        local exitPath,exitDirection,
            nextExitPath,nextExitDirection  = scoreNeighborsForRetreat(chunk,
                                                                       getNeighborChunks(map,
                                                                                         chunk.x,
                                                                                         chunk.y),
                                                                       scoreRetreatLocation,
                                                                       map)
        local position = {
            x = chunk.x + 16,
            y = chunk.y + 16
        }
        local retreatPosition
        local surface = map.surface
        if (exitPath == -1) then
            return
        elseif (nextExitPath ~= -1) then
            retreatPosition = findMovementPosition(
                surface,
                positionFromDirectionAndFlat(
                    nextExitDirection,
                    positionFromDirectionAndFlat(
                        exitDirection,
                        position
                    )
                )
            )
            exitPath = nextExitPath
        else
            retreatPosition = findMovementPosition(
                surface,
                positionFromDirectionAndFlat(
                    exitDirection,
                    position
                )
            )
        end

        if retreatPosition then
            position.x = retreatPosition.x
            position.y = retreatPosition.y
        else
            return
        end

        local newSquad = findNearbyRetreatingSquad(map, exitPath)
        local created = false

        if not newSquad then
            if (Universe.squadCount < Universe.AI_MAX_SQUAD_COUNT) then
                created = true
                local base = findNearbyBase(chunk)
                if not base then
                    return
                end
                newSquad = Squad.createSquad(position, map, nil, false, base)
            else
                return
            end
        end

        Universe.fleeCommand.from = cause
        Universe.retreatCommand.group = newSquad.group

        Universe.formRetreatCommand.unit_search_distance = radius

        local foundUnits = surface.set_multi_command(Universe.formRetreatCommand)

        if (foundUnits == 0) then
            if created then
                newSquad.group.destroy()
            end
            return
        end

        if created then
            Universe.groupNumberToSquad[newSquad.groupNumber] = newSquad
            Universe.squadCount = Universe.squadCount + 1
        end

        newSquad.status = SQUAD_RETREATING

        addSquadToChunk(chunk, newSquad)

        newSquad.frenzy = true
        local squadPosition = newSquad.group.position
        newSquad.frenzyPosition.x = squadPosition.x
        newSquad.frenzyPosition.y = squadPosition.y
    end
end

function Squad.createSquad(position, map, group, settlers, base)
    local unitGroup = group or map.surface.create_unit_group({position=position})

    local squad = {
        group = unitGroup,
        status = SQUAD_GUARDING,
        rabid = false,
        penalties = {},
        base = base,
        type = base.stateAI,
        frenzy = false,
        map = map,
        wanders = 0,
        settlers = settlers or false,
        kamikaze = false,
        frenzyPosition = {x = 0,
                          y = 0},
        maxDistance = 0,
        groupNumber = unitGroup.group_number,
        originPosition = {x = 0,
                          y = 0},
        commandTick = nil,
        chunk = -1
    }

    if settlers then
        squad.maxDistance = calculateSettlerMaxDistance()
    end

    if position then
        squad.originPosition.x = position.x
        squad.originPosition.y = position.y
    elseif group then
        squad.originPosition.x = group.position.x
        squad.originPosition.y = group.position.y
    end

    return squad
end

function Squad.calculateKamikazeSquadThreshold(memberCount)
    local threshold = (memberCount / Universe.attackWaveMaxSize) * 0.2 + (Universe.evolutionLevel * 0.2)
    return threshold
end

function Squad.calculateKamikazeSettlerThreshold(memberCount)
    local threshold = (memberCount / Universe.expansionMaxSize) * 0.2 + (Universe.evolutionLevel * 0.2)
    return threshold
end


local function settlerWaveScaling()
    return mCeil(gaussianRandomRangeRG(Universe.settlerWaveSize,
                                       Universe.settlerWaveDeviation,
                                       Universe.expansionMinSize,
                                       Universe.expansionMaxSize,
                                       Universe.random))
end

local function attackWaveScaling()
    return mCeil(gaussianRandomRangeRG(Universe.attackWaveSize,
                                       Universe.attackWaveDeviation,
                                       1,
                                       Universe.attackWaveUpperBound,
                                       Universe.random))
end

local function attackWaveValidCandidate(chunk)
    if isActiveNest(chunk) then
        return true
    end
    local base = chunk.base
    if (base.stateAI == BASE_AI_STATE_RAIDING) or
        (base.stateAI == BASE_AI_STATE_SIEGE) or
        (base.stateAI == BASE_AI_STATE_ONSLAUGHT)
    then
        return isActiveRaidNest(chunk)
    end
    return false
end

local function scoreSettlerLocation(neighborChunk)
    return neighborChunk[RESOURCE_PHEROMONE] + -neighborChunk[PLAYER_PHEROMONE]
end

local function scoreSiegeSettlerLocation(neighborChunk)
    return (neighborChunk[RESOURCE_PHEROMONE] + neighborChunk[BASE_PHEROMONE]) + -neighborChunk[PLAYER_PHEROMONE]
end

local function scoreUnitGroupLocation(neighborChunk)
    return neighborChunk[PLAYER_PHEROMONE] + neighborChunk[BASE_PHEROMONE]
end

local function validUnitGroupLocation(neighborChunk)
    return (getPassable(neighborChunk) == CHUNK_ALL_DIRECTIONS) and
        (not neighborChunk.nestCount)
end

local function visitPattern(o, cX, cY, distance)
    local startX
    local endX
    local stepX
    local startY
    local endY
    local stepY
    if (o == 0) then
        startX = cX - distance
        endX = cX + distance
        stepX = 32
        startY = cY - distance
        endY = cY + distance
        stepY = 32
    elseif (o == 1) then
        startX = cX + distance
        endX = cX - distance
        stepX = -32
        startY = cY + distance
        endY = cY - distance
        stepY = -32
    elseif (o == 2) then
        startX = cX - distance
        endX = cX + distance
        stepX = 32
        startY = cY + distance
        endY = cY - distance
        stepY = -32
    elseif (o == 3) then
        startX = cX + distance
        endX = cX - distance
        stepX = -32
        startY = cY - distance
        endY = cY + distance
        stepY = 32
    end
    return startX, endX, stepX, startY, endY, stepY
end

--[[
    Expects all neighbors adjacent to a chunk
--]]
local function scoreNeighborsForFormation(chunk, validFunction, scoreFunction)
    local highestChunk = -1
    local highestScore = -MAGIC_MAXIMUM_NUMBER
    local highestDirection
    local neighborChunks = getNeighborChunks(chunk.map, chunk.x, chunk.y)
    for x=1,8 do
        local neighborChunk = neighborChunks[x]
        if (neighborChunk ~= -1) and validFunction(neighborChunk) then
            local score = scoreFunction(neighborChunk)
            if (score > highestScore) then
                highestScore = score
                highestChunk = neighborChunk
                highestDirection = x
            end
        end
    end

    return highestChunk, highestDirection
end

function Squad.rallyUnits(chunk, tick)
    if (tick - getRallyTick(chunk)) < COOLDOWN_RALLY then
        return
    end
    setRallyTick(chunk, tick)
    local cX = chunk.x
    local cY = chunk.y
    local startX, endX, stepX, startY, endY, stepY = visitPattern(tick % 4, cX, cY, RALLY_CRY_DISTANCE)
    local vengenceQueue = Universe.vengenceQueue
    local map = chunk.map
    for x=startX, endX, stepX do
        for y=startY, endY, stepY do
            if (x ~= cX) and (y ~= cY) then
                local rallyChunk = getChunkByXY(map, x, y)
                if rallyChunk ~= -1 then
                    local base = rallyChunk.base
                    if rallyChunk.nestCount
                        and (base.unitPoints >= AI_VENGENCE_SQUAD_COST)
                    then
                        vengenceQueue[rallyChunk.id] = rallyChunk
                    end
                end
            end
        end
    end
end

local function deploySquad(name, chunk, cost, vengence, attacker)
    local base = chunk.base

    local lackingPoints = ((base.unitPoints - cost) < 0)
    if attacker then
        if lackingPoints
            or ((chunk[BASE_PHEROMONE] < 0.0001) and (chunk[PLAYER_PHEROMONE] < 0.0001))
            or (Universe.squadCount > Universe.AI_MAX_SQUAD_COUNT)
            or (not vengence and not attackWaveValidCandidate(chunk))
            or (Universe.random() > Universe.formSquadThreshold)
        then
            return
        end
    else
        if lackingPoints
            or (Universe.builderCount > Universe.AI_MAX_BUILDER_COUNT)
            or (not vengence and (base.sentExpansionGroups > base.maxExpansionGroups))
            or (Universe.random() > Universe.formSquadThreshold)
        then
            return
        end
    end

    local scoringFunction
    if attacker then
        scoringFunction = scoreUnitGroupLocation
    else
        scoringFunction = scoreSettlerLocation
        if base.stateAI == BASE_AI_STATE_SIEGE then
            scoringFunction = scoreSiegeSettlerLocation
        end
    end

    local squadPath, squadDirection = scoreNeighborsForFormation(
        chunk,
        validUnitGroupLocation,
        scoringFunction
    )
    if (squadPath == -1) then
        return
    end

    local map = chunk.map
    local surface = map.surface

    local squadPosition = findDeploymentPosition(
        surface,
        positionFromDirectionAndChunk(squadDirection,
                                      chunk,
                                      0.98)
    )

    if not squadPosition then
        return
    end

    local squad = Squad.createSquad(squadPosition, map, nil, not attacker, base)

    local scaledWaveSize
    if attacker then
        scaledWaveSize = attackWaveScaling()
    else
        scaledWaveSize = settlerWaveScaling()
    end
    Universe.formGroupCommand.group = squad.group
    Universe.formCommand.unit_count = scaledWaveSize
    local foundUnits = surface.set_multi_command(Universe.formCommand)
    if (foundUnits == 0) then
        if squad.group.valid then
            squad.group.destroy()
        end
        return
    end

    if attacker then
        squad.kamikaze = Universe.random() < Squad.calculateKamikazeSquadThreshold(foundUnits)
        Universe.squadCount = Universe.squadCount + 1
        if not vengence and (base.stateAI == BASE_AI_STATE_AGGRESSIVE) then
            base.sentAggressiveGroups = base.sentAggressiveGroups + 1
        end
    else
        local kamikazeThreshold = Squad.calculateKamikazeSettlerThreshold(foundUnits)
        if base.stateAI == BASE_AI_STATE_SIEGE then
            kamikazeThreshold = kamikazeThreshold * 2.5
        end
        squad.kamikaze = Universe.random() < kamikazeThreshold
        base.sentExpansionGroups = base.sentExpansionGroups + 1
        Universe.builderCount = Universe.builderCount + 1
    end

    squad.rabid = Universe.random() < 0.03

    Universe.groupNumberToSquad[squad.groupNumber] = squad
    modifyBaseUnitPoints(base, -cost, name, squadPosition.x, squadPosition.y)
end

function Squad.formSettlers(chunk)
    deploySquad("Settler", chunk, AI_SETTLER_COST, false, false)
end

function Squad.formVengenceSettler(chunk)
    deploySquad("Vengence Settler", chunk, AI_VENGENCE_SETTLER_COST, true, false)
end

function Squad.formSquads(chunk)
    deploySquad("Squad", chunk, AI_SQUAD_COST, false, true)
end

function Squad.formVengenceSquad(chunk)
    deploySquad("Vengence Squad", chunk, AI_VENGENCE_SQUAD_COST, true, true)
end

function Squad.init(universe)
    Universe = universe
end

SquadG = Squad
return Squad
