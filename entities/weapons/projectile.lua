local class = require("lib.hump.class")
local timer = require("lib.hump.timer")
local weaponutil = require("util.weapon")
local util = require("lib.self.util")

---

local clone = util.table.clone

---

local w_base = require("entities.weapons.base")
local w_projectile = class{__includes = w_base}

---

function w_projectile:init(arg)
	self.kind = arg.kind or "single"

	self.shot_heat = arg.shot_heat or 0.1
	self.projectile = arg.projectile
	self.projectile_speed = arg.projectile_speed or 800
	self.shot_delay = arg.shot_delay or 0.1
	self.spread = arg.spread or 0

	self.shot_sound = arg.shot_sound

	-- For burst fire
	self.burst_shots = arg.burst_shots or 3
	self.burst_shot_delay = arg.burst_shot_delay or 0.03

	self.shot_timer = 0

	w_base.init(self, arg)
end

---

function w_projectile:spawn_projectile(host, world, pos, dir)
	local projectile = clone(self.projectile)
	projectile.Position = pos + dir
	projectile.Velocity = self.projectile_speed * dir + host.Velocity
	projectile.Team = host.Team
	projectile.Firer = host

	--[[
	-- Add host to collision exclusion list.
	if not projectile.CollisionExcludeEntities then
		projectile.CollisionExcludeEntities = {host}
	else
		table.insert(projectile.CollisionExcludeEntities, host)
	end
	--]]

	world:spawn_entity(projectile)

	return projectile
end

function w_projectile:apply_recoil(host, projectile, dir)
	if not projectile.Mass then
		projectile.Mass = math.pi * projectile.Radius^2
	end

	host.Velocity = weaponutil.calculate_recoil_velocity(projectile.Mass,
		self.projectile_speed * dir, host.Mass, host.Velocity)
end

---

function w_projectile:fire_projectile(host, world, pos, dir)
	local angle = (love.math.random() - 0.5) * self.spread
	pos = pos + dir:perpendicular() * angle * 10
	dir = dir:rotated(angle)

	local p = self:spawn_projectile(host, world, pos, dir)
	self:apply_recoil(host, p, dir)

	return p, pos, dir
end

function w_projectile:play_shot_sound(world, host, pitch)
	if self.shot_sound then
		world:spawn_entity{
			Position = host.Position,
			Parent = host,
			Lifetime = 0.5,
			Sound = {
				source = love.audio.newSource(self.shot_sound),
				pitch = pitch
			}
		}
	end
end

function w_projectile:apply_shot_effects(host, world, pos, dir)
	self.shot_timer = self.shot_delay
	self.heat = self.heat + self.shot_heat

	host.ColorPulse = 1

	if self.shot_shake_intensity and self.shot_shake_duration then
		self:set_screenshake(self.shot_shake_intensity, self.shot_shake_duration)
	end
end

---

function w_projectile:fire(host, world, pos, dir)
	local p, pos, dir = self:fire_projectile(host, world, pos, dir)
	self:apply_shot_effects(host, world, pos, dir)
	self:play_shot_sound(world, host)
end

---

function w_projectile:firing(dt, host, world, pos, dir)
	if self.shot_timer == 0 then
		if (self.kind == "single" and not self.fired) or self.kind == "repeat" then
			self.fired = true
			self:fire(host, world, pos, dir)

		elseif self.kind == "burst" and not self.fired then
			self.fired = true

			-- TODO: Fix this so shots always come from the circle, not where you originally fired.

			local shot = 1
			timer.add(self.burst_shot_delay, function(func)
				self:fire(host, world, pos, dir)

				if shot < self.burst_shots then
					timer.add(self.burst_shot_delay, func)
				end

				shot = shot + 1
			end)
		end
	end

	w_base.firing(self, dt, host, world, pos, dir)
end

function w_projectile:cease(host, world)
	self.fired = false

	w_base.cease(self, host, world)
end

function w_projectile:update(dt, host, world)
	self.shot_timer = self.shot_timer - dt
	if self.shot_timer < 0 then
		self.shot_timer = 0
	end

	w_base.update(self, dt, host, world)
end

---

return w_projectile
