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

local biterUtils = require("BiterUtils")
local util = require ("util")

local droneUtils = {}

local DISALLOW_FRIENDLY_FIRE = settings.startup["rampant--disallowFriendlyFire"].value

function droneUtils.makeDrone(attributes)
    local n = attributes.name .. "-drone-rampant"
    local resistances = {}
    for k,v in pairs(attributes.resistances) do
        v.type = k
        resistances[#resistances+1] = v
    end
    -- attributes.name = name

    local drone = {
        type = "combat-robot",
        name = n,
        localised_name = biterUtils.getLocalisedName(attributes),
        icon = "__base__/graphics/icons/defender.png",
        icon_size = 32,
        flags = attributes.flags or {"placeable-off-grid", "not-on-map", "not-repairable", "breaths-air", "hidden"},
        subgroup="capsule",
        order="e-a-a",
        max_health = attributes.health or 60,
        healing_per_tick = attributes.healing,
        alert_when_damaged = false,
        collision_box = {{0, 0}, {0, 0}},
        collision_mask = {RampantGlobalVariables.projectileCollisionLayer},
        selection_box = {{-0.5, -1.5}, {0.5, -0.5}},
        distance_per_frame = attributes.distancePerFrame or 0,
        time_to_live = attributes.ttl or (60 * 45),
        follows_player = attributes.followsPlayer,
        friction = attributes.friction or 0.01,
        range_from_player = attributes.rangeFromPlayer or 6.0,
        speed = attributes.movement or 0,
        destroy_action = attributes.death,
        attack_parameters = attributes.attack,
        idle =
            {
                layers =
                    {
                        {
                            filename = "__base__/graphics/entity/defender-robot/defender-robot.png",
                            priority = "high",
                            line_length = 16,
                            width = 32,
                            tint = attributes.tint2,
                            height = 33,
                            frame_count = 1,
                            direction_count = 16,
                            shift = {0, 0.015625},
                            scale = attributes.scale,
                            hr_version = {
                                filename = "__base__/graphics/entity/defender-robot/hr-defender-robot.png",
                                priority = "high",
                                line_length = 16,
                                width = 56,
                                height = 59,
                                tint = attributes.tint2,
                                frame_count = 1,
                                direction_count = 16,
                                shift = util.by_pixel(0, 0.25),
                                scale = attributes.scale * 0.5
                            }
                        },
                        {
                            filename = "__base__/graphics/entity/defender-robot/defender-robot-mask.png",
                            priority = "high",
                            line_length = 16,
                            width = 18,
                            height = 16,
                            tint = attributes.tint2,
                            frame_count = 1,
                            direction_count = 16,
                            shift = {0, -0.125},
                            -- apply_runtime_tint = true,
                            scale = attributes.scale,
                            hr_version = {
                                filename = "__base__/graphics/entity/defender-robot/hr-defender-robot-mask.png",
                                priority = "high",
                                line_length = 16,
                                width = 28,
                                height = 21,
                                tint = attributes.tint2,
                                frame_count = 1,
                                direction_count = 16,
                                shift = util.by_pixel(0, -4.75),
                                -- apply_runtime_tint = true,
                                scale = attributes.scale * 0.5
                            }
                        },
                    }
            },
        shadow_idle =
            {
                filename = "__base__/graphics/entity/defender-robot/defender-robot-shadow.png",
                priority = "high",
                line_length = 16,
                width = 43,
                height = 23,
                frame_count = 1,
                direction_count = 16,
                shift = {0.859375, 0.609375},
                scale = attributes.scale,
                hr_version = {
                    filename = "__base__/graphics/entity/defender-robot/hr-defender-robot-shadow.png",
                    priority = "high",
                    line_length = 16,
                    width = 88,
                    height = 50,
                    frame_count = 1,
                    direction_count = 16,
                    shift = util.by_pixel(25.5, 19),
                    scale = attributes.scale * 0.5
                }
            },
        in_motion =
            {
                layers =
                    {
                        {
                            filename = "__base__/graphics/entity/defender-robot/defender-robot.png",
                            priority = "high",
                            line_length = 16,
                            width = 32,
                            tint = attributes.tint,
                            height = 33,
                            frame_count = 1,
                            direction_count = 16,
                            shift = {0, 0.015625},
                            y = 33,
                            scale = attributes.scale,
                            hr_version = {
                                filename = "__base__/graphics/entity/defender-robot/hr-defender-robot.png",
                                priority = "high",
                                line_length = 16,
                                width = 56,
                                tint = attributes.tint,
                                height = 59,
                                frame_count = 1,
                                direction_count = 16,
                                shift = util.by_pixel(0, 0.25),
                                y = 59,
                                scale = attributes.scale * 0.5
                            }
                        },
                        {
                            filename = "__base__/graphics/entity/defender-robot/defender-robot-mask.png",
                            priority = "high",
                            line_length = 16,
                            width = 18,
                            height = 16,
                            frame_count = 1,
                            direction_count = 16,
                            tint = attributes.tint2,
                            shift = {0, -0.125},
                            y = 16,
                            scale = attributes.scale,
                            hr_version = {
                                filename = "__base__/graphics/entity/defender-robot/hr-defender-robot-mask.png",
                                priority = "high",
                                line_length = 16,
                                width = 28,
                                height = 21,
                                frame_count = 1,
                                direction_count = 16,
                                tint = attributes.tint2,
                                shift = util.by_pixel(0, -4.75),
                                y = 21,
                                scale = attributes.scale * 0.5
                            }
                        },
                    }
            },
        shadow_in_motion =
            {
                filename = "__base__/graphics/entity/defender-robot/defender-robot-shadow.png",
                priority = "high",
                line_length = 16,
                width = 43,
                height = 23,
                frame_count = 1,
                direction_count = 16,
                shift = {0.859375, 0.609375},
                scale = attributes.scale,
                hr_version = {
                    filename = "__base__/graphics/entity/defender-robot/hr-defender-robot-shadow.png",
                    priority = "high",
                    line_length = 16,
                    width = 88,
                    height = 50,
                    frame_count = 1,
                    direction_count = 16,
                    shift = util.by_pixel(25.5, 19),
                    scale = attributes.scale * 0.5
                }
            }
    }
    if attributes.appendFlags then
        for flag in pairs(attributes.appendFlags) do
            drone.flags[#drone.flags+1] = flag
        end
    end
    return drone
end

function droneUtils.createCapsuleProjectile(attributes, entityName)
    local n = attributes.name .. "-capsule-rampant"

    local actions = {
        {
            type = "direct",
            force = (DISALLOW_FRIENDLY_FIRE and "not-same") or nil,
            action_delivery =
                {
                    type = "instant",
                    source_effects = attributes.sourceEffect and attributes.sourceEffect(attributes),
                    target_effects =
                        {
                            {
                                type = "create-entity",
                                show_in_tooltip = true,
                                trigger_created_entity = attributes.triggerCreated,
                                entity_name = entityName,
                                check_buildability = attributes.checkBuildability
                            },
                            {
                                type = "damage",
                                damage = {amount = attributes.damage or 5, type = attributes.damageType or "explosion"}
                            }
                        }
                }
        }
    }

    -- if attributes.sourceEffect then
    -- 	actions[#actions+1] = attributes.sourceEffect(attributes)
    -- end

    local cap = {
        type = "projectile",
        name = n,
        flags = {"not-on-map"},
        collision_box = attributes.collisionBox or {{-0.01, -0.01}, {0.01, 0.01}},
        collision_mask = attributes.collisionMask,
        direction_only = attributes.attackDirectionOnly,
        piercing_damage = attributes.piercingDamage or 0,
        force_condition = (settings.startup["rampant--disableCollidingProjectiles"].value and "not-same") or nil,
        acceleration = attributes.acceleration or 0.01,
        action = actions,
        light = {intensity = 0.5, size = 4},
        enable_drawing_with_mask = true,
        animation = {
            layers = {
                {
                    filename = "__base__/graphics/entity/combat-robot-capsule/defender-capsule.png",
                    flags = { "no-crop" },
                    frame_count = 1,
                    width = 28,
                    height = 20,
                    tint = attributes.tint2,
                    scale = attributes.scale,
                    priority = "high"
                },
                {
                    filename = "__base__/graphics/entity/combat-robot-capsule/defender-capsule-mask.png",
                    flags = { "no-crop" },
                    frame_count = 1,
                    width = 28,
                    height = 20,
                    tint = attributes.tint2,
                    scale = attributes.scale,
                    priority = "high",
                },
            },
        },
        shadow =
            {
                filename = "__base__/graphics/entity/combat-robot-capsule/defender-capsule-shadow.png",
                flags = { "no-crop" },
                frame_count = 1,
                width = 26,
                height = 20,
                scale = attributes.scale,
                priority = "high"
            },
        smoke = {
            {
                name = "the-soft-smoke-rampant",
                deviation = {0.15, 0.15},
                frequency = 1,
                position = {0, 0},
                starting_frame = 3,
                starting_frame_deviation = 5,
                starting_frame_speed_deviation = 5
            }
        }
    }

    data:extend({cap})
    return n
end

return droneUtils
