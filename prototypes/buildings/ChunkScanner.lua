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


local biterUtils = require("prototypes/utils/BiterUtils")
local constants = require("libs/Constants")
local smokeUtils = require("prototypes/utils/SmokeUtils")

local function generateCollisionBox(scale, entityType)
    if entityType == "turret" then
        return {
            {-1.1 * scale, -1.0 * scale},
            {1.1 * scale, 1.0 * scale}
        }
    elseif (entityType == "biter-spawner") or (entityType == "spitter-spawner") then
        return {
            {-3 * scale, -2 * scale},
            {2 * scale, 2 * scale}
        }
    elseif entityType == "hive" then
        return {
            {-3 * scale, -2 * scale},
            {2 * scale, 2 * scale}
        }
    end
end

local scales = {
    -- ["trap"] = {},
    -- ["utility"] = {},
    ["spitter-spawner"] = {
        [1] = 0.70, [2] = 0.83, [3] = 0.96, [4] = 1.09, [5] = 1.22,
        [6] = 1.35, [7] = 1.48, [8] = 1.61, [9] = 1.74, [10] = 1.87
    },
    ["biter-spawner"] = {
        [1] = 0.83, [2] = 0.96, [3] = 1.09, [4] = 1.22, [5] = 1.35,
        [6] = 1.48, [7] = 1.61, [8] = 1.74, [9] = 1.87, [10] = 2.0
    },
    ["hive"] = {
        [1] = 1.35, [2] = 1.48, [3] = 1.61, [4] = 1.74, [5] = 1.87,
        [6] = 2.0, [7] = 2.13, [8] = 2.26, [9] = 2.39, [10] = 2.52
    },
    ["turret"] = {
        [1] = 0.635, [2] = 0.765, [3] = 0.895, [4] = 1.025, [5] = 1.155,
        [6] = 1.285, [7] = 1.415, [8] = 1.545, [9] = 1.675, [10] = 1.805
    }
}

local subTypes = constants.HIVE_BUILDINGS_TYPES


for si=1,#subTypes do
    local st = subTypes[si]
    if scales[st] then
        for t=1,constants.TIERS do
            -- local scale = scales[st][t]
            local scale = scales["biter-spawner"][t]

            local eggPicture
            if (st == "turret") then
                eggPicture = {
                    filename = "__base__/graphics/entity/spawner/hr-spawner-idle-integration.png",
                    -- priority = "very-low",
                    -- flags = {"low-object"},
                    draw_as_shadow = true,
                    scale = 0.25,
                    width = 522,
                    height = 380
                }
            elseif (st == "biter-spawner") or (st == "spitter-spawner") then
                eggPicture = {
                    filename = "__base__/graphics/entity/spawner/hr-spawner-idle-integration.png",
                    -- priority = "very-low",
                    -- flags = {"low-object"},
                    draw_as_shadow = true,
                    scale = 0.5,
                    width = 522,
                    height = 380
                }
            elseif (st == "hive") then
                eggPicture = {
                    filename = "__base__/graphics/entity/spawner/hr-spawner-idle-integration.png",
                    -- priority = "very-low",
                    -- flags = {"low-object"},
                    draw_as_shadow = true,
                    scale = 0.75,
                    width = 522,
                    height = 380
                }
            -- else
            --     eggPicture = {
            --         filename = "__core__/graphics/empty.png",
            --         priority = "extra-high",
            --         width = 1,
            --         height = 1
            --     }
            end

            data:extend(
                {
                    {
                        type = "simple-entity-with-force",
                        name = "entity-proxy-" .. st .. "-t" .. t .. "-rampant",
                        localised_name = biterUtils.getLocalisedName({
                                faction="entity-proxy",
                                unit_name=st,
                                tier=t,
                                isRampant=true
                        }),
                        icon = "__base__/graphics/icons/steel-chest.png",
                        icon_size = 32,
                        flags = {},
                        build_base_evolution_requirement = 0.08 * (t-1),
                        collision_mask = {"player-layer", "object-layer", "water-tile", "train-layer"},
                        minable = nil,
                        max_health = 300 * t,
                        corpse = nil,
                        collision_box = generateCollisionBox(scale, "biter-spawner"),
                        selection_box = generateCollisionBox(scale, "biter-spawner"),

                        picture = eggPicture,

                        created_effect = {
                            {
                                type = "direct",
                                action_delivery = {
                                    type = "instant",
                                    source_effects = {
                                        type = "script",
                                        effect_id = "hive-spawned--rampant"
                                    }
                                }
                            }
                        }
                    }
                }
            )
        end
    end
end


smokeUtils.makeNewCloud(
    {
        name = "build-clear",
        wind = false,
        scale = 9,
        duration = 540,
        cooldown = 10,
        tint = { r=0.7, g=0.2, b=0.7 }
    },
    {
        type = "area",
        radius = 17,
        force = "not-same",
        action_delivery =
            {
                type = "instant",
                target_effects =
                    {
                        {
                            type = "damage",
                            damage = { amount = 1.1, type = "poison"}
                        },
                        {
                            type = "damage",
                            damage = { amount = 1.1, type = "acid"}
                        },
                        {
                            type = "damage",
                            damage = { amount = 1.1, type = "fire"}
                        }
                    }
            }
    }
)
