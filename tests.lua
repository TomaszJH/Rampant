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


local tests = {}

local constants = require("libs/Constants")
local mathUtils = require("libs/MathUtils")
local chunkUtils = require("libs/ChunkUtils")
local chunkPropertyUtils = require("libs/ChunkPropertyUtils")
local mapUtils = require("libs/MapUtils")
local baseUtils = require("libs/BaseUtils")
local Utils = require("libs/Utils")
-- local tendrilUtils = require("libs/TendrilUtils")

function tests.chunkCount()
    local count = 0
    for _,map in pairs(global.universe.maps) do
        count = count + #map.processQueue
    end
    print(count)
end

function tests.pheromoneLevels(size)
    local player = game.player.character
    local playerChunkX = math.floor(player.position.x / 32) * constants.CHUNK_SIZE
    local playerChunkY = math.floor(player.position.y / 32) * constants.CHUNK_SIZE
    if not size then
        size = 3 * constants.CHUNK_SIZE
    else
        size = size * constants.CHUNK_SIZE
    end
    print("------")
    print(#global.map.processQueue)
    print(playerChunkX .. ", " .. playerChunkY)
    print("--")
    for y=playerChunkY-size, playerChunkY+size,32 do
        for x=playerChunkX-size, playerChunkX+size,32 do
            if (global.map[x] ~= nil) then
                local chunk = global.map[x][y]
                if (chunk ~= nil) then
                    local str = ""
                    for i=1,#chunk do
                        str = str .. " " .. tostring(i) .. "/" .. tostring(chunk[i])
                    end
                    str = str .. " " .. "p/" .. game.get_surface(global.natives.activeSurface).get_pollution(chunk) .. " " .. "n/" .. chunkPropertyUtils.getNestCount(global.map, chunk) .. " " .. "w/" .. chunkPropertyUtils.getTurretCount(global.map, chunk) .. " pg/" .. chunkPropertyUtils.getPlayerBaseGenerator(global.map, chunk)
                    if (chunk.x == playerChunkX) and (chunk.y == playerChunkY) then
                        print("=============")
                        print(chunk.x, chunk.y, str)
                        print("=============")
                    else
                        print(chunk.x, chunk.y, str)
                    end
                    -- print(str)
                    print("----")
                end
            end
        end
        print("------------------")
    end
end

function tests.killActiveSquads()
    print("--")
    for i=1, global.natives.squads.len do
        local squad = global.natives.squads[i]
        if (squad.group.valid) then
            local members = squad.group.members
            for x=1, #members do
                local member = members[x]
                local val = member.valid and member.die()
            end
        end
    end
end

function tests.activeSquads()
    print("-----")
    print(defines.group_state.gathering .. " is equal to gathering")
    print(defines.group_state.finished .. " is equal to finished")
    -- print("Squads", global.natives.groupNumberToSquad)
    for un, squad in pairs(global.natives.groupNumberToSquad) do
        print("-")
        -- local squad = global.natives.squads[i]
        local squadHealth = 0
        local squadMakeup = {}
        if squad.group.valid then
            -- for x=1,#squad.group.members do
            --     local member = squad.group.members[x].prototype
            --     if not squadMakeup[member.name] then
            --         squadMakeup[member.name] = 0
            --     end

            --     squadHealth = squadHealth + member.max_health
            --     squadMakeup[member.name] = squadMakeup[member.name] + 1
            -- end
            print(math.floor(squad.group.position.x * 0.03125), math.floor(squad.group.position.y * 0.03125), squad.status, squad.group.state, #squad.group.members, squad.cycles, squad.group.group_number -- , squadHealth
            )
            -- print(serpent.dump(squadResistances))
            -- print(serpent.dump(squadMakeup))
            -- print(serpent.dump(squad))
        end
    end
    -- print("---")
    -- print("pending", global.natives.pendingAttack.len)
    -- for i=1, global.natives.pendingAttack.len do
    --     print("-")
    --     local squad = global.natives.pendingAttack[i]
    --     local squadHealth = 0
    --     local squadMakeup = {}
    --     if squad.group.valid then
    --         -- for x=1,#squad.group.members do
    --         --     local member = squad.group.members[x].prototype
    --         --     if not squadMakeup[member.name] then
    --         --         squadMakeup[member.name] = 0
    --         --     end

    --         --     squadHealth = squadHealth + member.max_health
    --         --     squadMakeup[member.name] = squadMakeup[member.name] + 1
    --         -- end
    --         print(math.floor(squad.group.position.x * 0.03125), math.floor(squad.group.position.y * 0.03125), squad.status, squad.group.state, #squad.group.members, squad.cycles, -- squadHealth,
    --               squad.group.group_number)
    --         -- print(serpent.dump(squadResistances))
    --         -- print(serpent.dump(squadMakeup))
    --         -- print(serpent.dump(squad))
    --     end
    -- end
    -- print("---")
    -- print("building", #global.natives.building)
    -- for i=1, #global.natives.building do
    --     print("-")
    --     local squad = global.natives.building[i]
    --     local squadHealth = 0
    --     local squadMakeup = {}
    --     if squad.group.valid then
    --         -- for x=1,#squad.group.members do
    --         --     local member = squad.group.members[x].prototype
    --         --     if not squadMakeup[member.name] then
    --         --         squadMakeup[member.name] = 0
    --         --     end

    --         --     squadHealth = squadHealth + member.max_health
    --         --     squadMakeup[member.name] = squadMakeup[member.name] + 1
    --         -- end
    --         print(math.floor(squad.group.position.x * 0.03125), math.floor(squad.group.position.y * 0.03125), squad.status, squad.group.state, #squad.group.members, squad.cycles, squad.group.group_number, squadHealth)
    --         -- print(serpent.dump(squadResistances))
    --         -- print(serpent.dump(squadMakeup))
    --         -- print(serpent.dump(squad))
    --     end
    -- end

end

function tests.entitiesOnPlayerChunk()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local entities = game.get_surface(global.natives.activeSurface).find_entities_filtered({area={{chunkX, chunkY},
                                                                                                {chunkX + constants.CHUNK_SIZE, chunkY + constants.CHUNK_SIZE}},
                                                                                            force="player"})
    for i=1, #entities do
        print(entities[i].name)
    end
    print("--")
end

function tests.findNearestPlayerEnemy()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local entity = game.get_surface(global.natives.activeSurface).find_nearest_enemy({position={chunkX, chunkY},
                                                                                      max_distance=constants.CHUNK_SIZE,
                                                                                      force = "enemy"})
    if (entity ~= nil) then
        print(entity.name)
    end
    print("--")
end

function tests.morePoints(points)
    global.natives.points = global.natives.points + points
end

function tests.getOffsetChunk(x, y)
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125)
    local chunkY = math.floor(playerPosition.y * 0.03125)
    local chunk = mapUtils.getChunkByIndex(global.map, chunkX + x, chunkY + y)
    print(serpent.dump(chunk))
end

function tests.aiStats()
    print(global.natives.points, game.tick, global.natives.state, global.natives.temperament, global.natives.stateTick, global.natives.temperamentTick, global.natives.activeNests, global.natives.activeRaidNests)
end

function tests.fillableDirtTest()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    game.get_surface(global.natives.activeSurface).set_tiles({{name="fillableDirt", position={chunkX-1, chunkY-1}},
            {name="fillableDirt", position={chunkX, chunkY-1}},
            {name="fillableDirt", position={chunkX-1, chunkY}},
            {name="fillableDirt", position={chunkX, chunkY}}},
        false)
end

function tests.tunnelTest()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    game.get_surface(global.natives.activeSurface).create_entity({name="tunnel-entrance-rampant", position={chunkX, chunkY}})
end

function tests.createEnemy(x,d)
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local a = {name=x, position={chunkX, chunkY}, force="enemy"}
    if d then
        a['direction'] = d
    end
    return game.get_surface(global.natives.activeSurface).create_entity(a)
end

function tests.attackOrigin()
    local enemy = game.get_surface(global.natives.activeSurface).find_nearest_enemy({position={0,0},
                                                                                     max_distance = 1000})
    if (enemy ~= nil) and enemy.valid then
        print(enemy, enemy.unit_number)
        enemy.set_command({type=defines.command.go_to_location,
                           destination={0,0},
                           radius=15})
    end
end

function tests.dumpNatives()
    print(serpent.dump(global.natives))
end

function tests.cheatMode()
    game.players[1].cheat_mode = true
    game.forces.player.research_all_technologies()
end

function tests.gaussianRandomTest()
    local result = {}
    for x=0,100,1 do
        result[x] = 0
    end
    for _=1,10000 do
        local s = mathUtils.roundToNearest(mathUtils.gaussianRandomRange(50, 25, 0, 100), 1)
        result[s] = result[s] + 1
    end
    for x=0,100,1 do
        print(x, result[x])
    end
end

function tests.reveal (size)
    local pos = game.player.character.position
    game.player.force.chart(game.player.surface,
                            {{x=-size+pos.x, y=-size+pos.y}, {x=size+pos.x, y=size+pos.y}})
end

function tests.baseStats()
    local natives = global.natives
    print ("x", "y", "distanceThreshold", "tick", "points", "temperament", "temperamentTick", "state", "stateTick", "alignments")
    for i=1, #natives.bases do
        local base = natives.bases[i]
        print(base.x,
              base.y,
              base.distanceThreshold,
              base.tick,
              base.points,
              base.temperament,
              base.temperamentTick,
              base.state,
              base.stateTick,
              serpent.dump(base.alignment))
        print("---")
    end
end

function tests.clearBases()

    local surface = game.get_surface(global.natives.activeSurface)
    for x=#global.natives.bases,1,-1 do
        local base = global.natives.bases[x]
        for c=1,#base.chunks do
            local chunk = base.chunks[c]
            chunkUtils.clearChunkNests(chunk, surface)
        end

        base.chunks = {}

        if (surface.can_place_entity({name="biter-spawner-powered", position={base.cX * 32, base.cY * 32}})) then
            surface.create_entity({name="biter-spawner-powered", position={base.cX * 32, base.cY * 32}})
            local slice = math.pi / 12
            local pos = 0
            for i=1,24 do
                if (math.random() < 0.8) then
                    local distance = mathUtils.roundToNearest(mathUtils.gaussianRandomRange(45, 5, 37, 60), 1)
                    if (surface.can_place_entity({name="biter-spawner", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})) then
                        if (math.random() < 0.3) then
                            surface.create_entity({name="small-worm-turret", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})
                        else
                            surface.create_entity({name="biter-spawner", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})
                        end
                    end
                end
                pos = pos + slice
            end
        else
            table.remove(global.natives.bases, x)
        end
    end
end

function tests.mergeBases()
    local natives = global.natives
    baseUtils.mergeBases(global.natives)
end

function tests.unitBuildBase()
end

function tests.showBaseGrid(time)
    local map = global.universe.maps[game.player.surface.index]
    local chunks = map.chunkToBase
    for chunk in pairs(chunks) do
        local count = chunkPropertyUtils.getEnemyStructureCount(map, chunk)
        chunkUtils.mapScanEnemyChunk(chunk, map, game.tick)
        local newCount = chunkPropertyUtils.getEnemyStructureCount(map, chunk)
        if newCount ~= count then
            constants.gpsDebug(chunk.x+16,chunk.y+16, "f2:" .. tostring(count) .. "/" .. tostring(newCount))
            chunkUtils.colorChunk(chunk, game.player.surface.index, {0.3, 0.1, 0.1, 0.6}, time and tonumber(time))
        else
            chunkUtils.colorChunk(chunk, game.player.surface.index, nil, time and tonumber(time))
        end
    end
end

function tests.getEnemyStructureCount()
    local map = global.universe.maps[game.player.surface.index]
    local chunk = mapUtils.getChunkByPosition(map, game.player.character.position)

    print(chunk.x, chunk.y, chunkPropertyUtils.getEnemyStructureCount(map, chunk))
end

function tests.scanEnemy()
    local map = global.universe.maps[game.player.surface.index]
    local chunk = mapUtils.getChunkByPosition(map, game.player.character.position)
    local universe = map.universe
    local query = universe.filteredEntitiesEnemyStructureQuery
    Utils.setAreaInQuery(query, chunk, constants.CHUNK_SIZE)
    local buildings = map.surface.find_entities_filtered(query)
    local counts = map.chunkScanCounts
    for i=1,#constants.HIVE_BUILDINGS_TYPES do
        counts[constants.HIVE_BUILDINGS_TYPES[i]] = 0
    end
    for i=1,#buildings do
        local building = buildings[i]
        local hiveType = constants.BUILDING_HIVE_TYPE_LOOKUP[building.name] or
            (((building.type == "turret") and "turret") or "biter-spawner")
        counts[hiveType] = counts[hiveType] + 1
    end

    print(game.tick, serpent.dump(counts))
end

function tests.showMovementGrid()
    local chunks = global.map.processQueue
    for i=1,#chunks do
        local chunk = chunks[i]
        local color = "concrete"
        if (chunkPropertyUtils.getPassable(global.map, chunk) == constants.CHUNK_ALL_DIRECTIONS) then
            color = "hazard-concrete-left"
        elseif (chunkPropertyUtils.getPassable(global.map, chunk) == constants.CHUNK_NORTH_SOUTH) then
            color = "concrete"
        elseif (chunkPropertyUtils.getPassable(global.map, chunk) == constants.CHUNK_EAST_WEST) then
            color = "stone-path"
        end
        chunkUtils.colorChunk(chunk.x, chunk.y, color, game.get_surface(global.natives.activeSurface))
    end
end

function tests.colorResourcePoints()
    local chunks = global.map.processQueue
    for i=1,#chunks do
        local chunk = chunks[i]
        local color = "concrete"
        if (chunk[constants.RESOURCE_GENERATOR] ~= 0) and (chunk[constants.NEST_COUNT] ~= 0) then
            color = "hazard-concrete-left"
        elseif (chunk[constants.RESOURCE_GENERATOR] ~= 0) then
            color = "deepwater"
        elseif (chunk[constants.NEST_COUNT] ~= 0) then
            color = "stone-path"
        end
        chunkUtils.colorChunk(chunk.x, chunk.y, color, game.get_surface(global.natives.activeSurface))
    end
end

function tests.entityStats(name, d)
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local a = game.get_surface(global.natives.activeSurface).create_entity({name=name, position={chunkX, chunkY}})
    if d then
        a['direction'] = d
    end
    print(serpent.dump(a))
    a.destroy()
end

local function lookupIndexFaction(targetFaction)
    for i=1,#constants.FACTION_SET do
        if constants.FACTION_SET[i].type == targetFaction then
            return i
        end
    end
    return 0
end

local function scoreResourceLocationKamikaze(_, neighborChunk)
    local settle = neighborChunk[constants.RESOURCE_PHEROMONE]
    return settle
        - (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
        - neighborChunk[constants.ENEMY_PHEROMONE]
end

local function scoreSiegeLocationKamikaze(_, neighborChunk)
    local settle = neighborChunk[constants.BASE_PHEROMONE]
        + neighborChunk[constants.RESOURCE_PHEROMONE] * 0.5
        + (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
        - neighborChunk[constants.ENEMY_PHEROMONE]

    return settle
end

local function scoreResourceLocation(map, neighborChunk)
    local settle = (neighborChunk[constants.RESOURCE_PHEROMONE])
    return settle
        - (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
        - neighborChunk[constants.ENEMY_PHEROMONE]
end

local function scoreSiegeLocation(map, neighborChunk)
    local settle = neighborChunk[constants.BASE_PHEROMONE]
        + neighborChunk[constants.RESOURCE_PHEROMONE] * 0.5
        + (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
        - neighborChunk[constants.ENEMY_PHEROMONE]

    return settle
end

local function scoreAttackLocation(map, neighborChunk)
    local damage = neighborChunk[constants.BASE_PHEROMONE] +
        (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
    return damage
end

local function scoreAttackKamikazeLocation(_, neighborChunk)
    local damage = neighborChunk[constants.BASE_PHEROMONE] + (neighborChunk[constants.PLAYER_PHEROMONE] * constants.PLAYER_PHEROMONE_MULTIPLER)
    return damage
end

function tests.exportAiState()

    local printState = function ()
        local map = global.universe.maps[game.players[1].surface.index]
        local chunks = map.processQueue
        local s = ""
        for i=1,#chunks do
            local chunk = chunks[i]

            local base = chunkPropertyUtils.getChunkBase(map, chunk)
            local alignmentCount = 0

            if base then
                if (#base.alignment == 2) then
                    alignmentCount = (math.abs(base.x) * 10000) + (math.abs(base.y) * 10000) + (lookupIndexFaction(base.alignment[1]) * 100) + lookupIndexFaction(base.alignment[2])
                else
                    alignmentCount = (math.abs(base.x) * 10000) + (math.abs(base.y) * 10000) + lookupIndexFaction(base.alignment[1])
                end
            end

            s = s .. table.concat({chunk.x,
                                   chunk.y,
                                   chunkPropertyUtils.getCombinedDeathGeneratorRating(map, chunk),
                                   chunk[constants.BASE_PHEROMONE],
                                   chunk[constants.PLAYER_PHEROMONE],
                                   chunk[constants.RESOURCE_PHEROMONE],
                                   chunk[constants.ENEMY_PHEROMONE],
                                   chunkPropertyUtils.getPassable(map, chunk),
                                   chunk[constants.CHUNK_TICK],
                                   chunkPropertyUtils.getPathRating(map, chunk),
                                   chunkPropertyUtils.getNestCount(map, chunk),
                                   chunkPropertyUtils.getTurretCount(map, chunk),
                                   chunkPropertyUtils.getRallyTick(map, chunk),
                                   chunkPropertyUtils.getRetreatTick(map, chunk),
                                   chunkPropertyUtils.getResourceGenerator(map, chunk),
                                   chunkPropertyUtils.getPlayerBaseGenerator(map, chunk),
                                   chunkPropertyUtils.getCombinedDeathGenerator(map, chunk),
                                   scoreResourceLocationKamikaze(map, chunk),
                                   scoreResourceLocation(map, chunk),
                                   scoreSiegeLocationKamikaze(map, chunk),
                                   scoreSiegeLocation(map, chunk),
                                   scoreAttackKamikazeLocation(map, chunk),
                                   scoreAttackLocation(map, chunk),
                                   game.get_surface(game.players[1].surface.index).get_pollution(chunk),
                                   chunkPropertyUtils.getNestActiveness(map, chunk),
                                   chunkPropertyUtils.getRaidNestActiveness(map, chunk),
                                   table_size(chunkPropertyUtils.getSquadsOnChunk(map, chunk)),
                                   alignmentCount,
                                   chunkPropertyUtils.getHiveCount(map, chunk),
                                   chunkPropertyUtils.getTrapCount(map, chunk),
                                   chunkPropertyUtils.getUtilityCount(map, chunk),
                                   global.universe.chunkToVictory[chunk] or 0
                                  }, ",") .. "\n"
        end
        game.write_file("rampantState.txt", s, false)
    end

    return function(interval)
        if not interval then
            interval = 0
        else
            interval = tonumber(interval)
        end

        printState()

        if (interval > 0) then
            script.on_nth_tick(interval, printState)
        end
    end
end

function tests.createEnergyTest(x)
    local entity = tests.createEnemy(x)

    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local entities = game.get_surface(global.natives.activeSurface).find_entities_filtered({area={{chunkX, chunkY},
                                                                                                {chunkX + constants.CHUNK_SIZE, chunkY + constants.CHUNK_SIZE}},
                                                                                            type = "electric-pole",
                                                                                            force="player"})
    -- for i=1, #entities do
    --     print(entities[i].name)
    -- end
    local wires

    if #entities > 0 then
        entity.connect_neighbour(entities[1])
    end

    --     if wires then
    -- 	for connectType,neighbourGroup in pairs(wires) do
    -- 	    if connectType == "copper" then
    -- 		for _,v in pairs(neighbourGroup) do
    -- ;
    -- 		end
    -- 	    end
    -- 	end
    --     end
end

-- function tests.unitGroupBuild()
--     local surface = game.get_surface(global.natives.activeSurface)
--     local group = surface.create_unit_group({position={-32, -32}})

--     for i=1,10 do
--         group.add_member(surface.create_entity({name="small-biter", position={-32, -32}}))
--     end

--     group.set_command({
--             type = defines.command.build_base,
--             destination = {-64, -64},
--             distraction = defines.distraction.by_enemy,
--             ignore_planner = true
--     })
-- end

function tests.unitGroupBuild()
    local surface = game.get_surface(global.natives.activeSurface)
    local group = surface.create_unit_group({position={-32, -32}})

    for i=1,10 do
        group.add_member(surface.create_entity({name="small-biter", position={-32, -32}}))
        -- surface.create_entity({name="small-biter", position={-32, -32}})
    end

    local group2 = surface.create_unit_group({position={32, 32}})

    for i=1,10 do
        -- group2.add_member(surface.create_entity({name="small-biter", position={32, 32}}))
        surface.create_entity({name="small-biter", position={32, 32}})
    end

    group.destroy()

    -- group.set_command({
    --         type = defines.command.build_base,
    --         destination = {-64, -64},
    --         distraction = defines.distraction.by_enemy,
    --         ignore_planner = true
    -- })

    surface.set_multi_command({
            command = {
                type = defines.command.group,
                group = group2,
                distraction = defines.distraction.none,
                use_group_distraction = false
            },
            unit_count = 900,
            unit_search_distance = 32 * 8
    })

end

function tests.dumpEnvironment(x)
    print (serpent.dump(global[x]))
end

-- function tests.scanChunkPaths()
--     local surface = game.get_surface(global.natives.activeSurface)
--     local playerPosition = game.players[1].position
--     local chunk = mapUtils.getChunkByPosition(global.map, playerPosition)
--     print("------")
--     print(chunkUtils.scanChunkPaths(chunk, surface, global.map))
--     print("------")
-- end

function tests.stepAdvanceTendrils()
    -- for _, base in pairs(global.natives.bases) do
    -- 	tendrilUtils.advanceTendrils(global.map, base, game.get_surface(global.natives.activeSurface), {nil,nil,nil,nil,nil,nil,nil,nil})
    -- end
end

return tests
