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


local projectileUtils = {}

function projectileUtils.makeProjectile(attributes, attack)
    local n = attributes.name .. "-projectile-rampant"

    data:extend({{
                type = "projectile",
                name = n,
                flags = {"not-on-map"},
                collision_box = attributes.attackCollisionBox or {{-0.025, -0.025}, {0.025, 0.025}},
                hit_collision_mask = attributes.attackCollisionMask or {"player-layer", "train-layer", RampantGlobalVariables.projectileCollisionLayer},
                direction_only = attributes.attackDirectionOnly,
                hit_at_collision_position = true,
                piercing_damage = attributes.attackPiercingDamage or 0,
                acceleration = attributes.attackAcceleration or 0.000001,
                max_speed = math.min(math.max(attributes.scale*0.60, 0.4), 0.7),
                force_condition = (settings.startup["rampant--disableCollidingProjectiles"].value and "not-same") or nil,
                action = attack,
                animation =
                    {
                        filename = "__base__/graphics/entity/acid-projectile/acid-projectile-head.png",
                        line_length = 5,
                        width = 22,
                        height = 84,
                        frame_count = 15,
                        shift = util.mul_shift(util.by_pixel(-2, 30), attributes.scale*1.2 or 1),
                        tint = attributes.tint2,
                        priority = "high",
                        scale = (attributes.scale*1.2 or 1),
                        animation_speed = 1,
                        hr_version =
                            {
                                filename = "__base__/graphics/entity/acid-projectile/hr-acid-projectile-head.png",
                                line_length = 5,
                                width = 42,
                                height = 164,
                                frame_count = 15,
                                shift = util.mul_shift(util.by_pixel(-2, 31), attributes.scale*1.2 or 1),
                                tint = attributes.tint2,
                                priority = "high",
                                scale = 0.5 * (attributes.scale*1.2 or 1),
                                animation_speed = 1,
                            }
                    },
                shadow =
                    {
                        filename = "__base__/graphics/entity/acid-projectile/acid-projectile-shadow.png",
                        line_length = 15,
                        width = 22,
                        height = 84,
                        frame_count = 15,
                        priority = "high",
                        shift = util.mul_shift(util.by_pixel(-2, 30), attributes.scale*1.2 or 1),
                        draw_as_shadow = true,
                        scale = (attributes.scale*1.2 or 1),
                        animation_speed = 1,
                        hr_version =
                            {
                                filename = "__base__/graphics/entity/acid-projectile/hr-acid-projectile-shadow.png",
                                line_length = 15,
                                width = 42,
                                height = 164,
                                frame_count = 15,
                                shift = util.mul_shift(util.by_pixel(-2, 31), attributes.scale*1.2 or 1),
                                draw_as_shadow = true,
                                priority = "high",
                                scale = 0.5 * (attributes.scale*1.2 or 1),
                                animation_speed = 1,
                            }
                    },
                -- rotatable = false,
                oriented_particle = true,
                shadow_scale_enabled = true,

    }})

    return n
end

return projectileUtils
