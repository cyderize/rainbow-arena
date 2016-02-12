--- Require ---
local Class = require("lib.hump.class")
local vector = require("lib.hump.vector")

local tiny = require("lib.tiny")

local util = require("lib.util")

local circle = require("util.circle")
--- ==== ---


--- System definition ---
local sys_DrawEntity = tiny.processingSystem()
sys_DrawEntity.filter = tiny.requireAll("Position", "Radius", "Color")

sys_DrawEntity.isDrawSystem = true
--- ==== ---


--- Constants ---
local INTENSITY_DECAY_RATE = 2

local MIN_INTENSITY = 0.3
local MAX_INTENSITY = 0.7

local MAX_PULSE_SPEED = 500
--- ==== ---


--- Local functions ---
local function calculate_single_entity_pulse(e, velocity)
	return (velocity or e.Velocity:len()) / MAX_PULSE_SPEED
end

local function calculate_double_entity_pulse(e1, e2)
	local diff = e1.Position - e2.Position

	local v1 = e1.Velocity:projectOn(diff)
	local v2 = e2.Velocity:projectOn(diff)

	print("e1 was going at", e1.Velocity:len())
	print("e2 was going at", e2.Velocity:len())

	print("e1's common velocity was", v1:len())
	print("e2's common velocity was", v2:len())

	local vf = (v1 + v2):len()

	local res1 = calculate_single_entity_pulse(e1, v1:len())
	local res2 = calculate_single_entity_pulse(e2, v2:len())

	print(res1, res2)

	return res1, res2
end

---

local function draw_entity_circle(e)
	local pos = e.Position
	local radius = e.Radius
	local color = e.Color

	if not e.ColorIntensity then
		e.ColorIntensity = 0
	else
		e.ColorIntensity = util.math.clamp(0, e.ColorIntensity, 1)
	end

	local amp = util.math.map(e.ColorIntensity, 0,1, MIN_INTENSITY,MAX_INTENSITY)

	---

	-- Fill radius is based on health.
	local fill_radius = radius
	if e.Health and e.MaxHealth then
		fill_radius = fill_radius * (util.math.clamp(0, e.Health / e.MaxHealth, 1))
	end
	love.graphics.setColor(color[1] * amp, color[2] * amp, color[3] * amp)
	love.graphics.circle("fill", pos.x, pos.y, fill_radius)


	love.graphics.setColor(color)
	love.graphics.circle("line", pos.x, pos.y, radius)
end

local function draw_entity_aiming(e)
	local radius = e.Radius
	local sx, sy = e.Position:unpack()
	local angle = e.AimAngle
	local ex, ey = sx + radius * math.cos(angle), sy + radius * math.sin(angle)

	love.graphics.setColor(e.Color)
	love.graphics.line(sx,sy, ex,ey)
end


local function draw_entity_debug_info(e)
	local str_t = {}

	---

	--str_t[#str_t + 1] = (""):format()

	str_t[#str_t + 1] = ("Position: (%.2f, %.2f)"):format(e.Position.x, e.Position.y)

	if e.Velocity then
		str_t[#str_t + 1] = ("Velocity: (%.2f, %.2f)"):format(e.Velocity.x, e.Velocity.y)
	end

	if e.ColorIntensity then
		str_t[#str_t + 1] = ("ColorIntensity: %.2f"):format(e.ColorIntensity)
	end

	---

	local str = table.concat(str_t, "\n")

	local text_w = love.graphics.getFont():getWidth(str)

	local x = e.Position.x - text_w/2
	local y = e.Position.y + e.Radius + 10

	love.graphics.setColor(255, 255, 255)
	love.graphics.print(str, math.floor(x), math.floor(y))
end

---

local function restore_color_amp(e, dt)
	local step = INTENSITY_DECAY_RATE*dt

	if e.ColorIntensity < step then
		e.ColorIntensity = 0
	elseif e.ColorIntensity > 0 then
		e.ColorIntensity = e.ColorIntensity - step
	end
end
--- ==== ---


--- System functions ---
function sys_DrawEntity:onAddToWorld(world)
	local world = world.world

	-- Combatants blink upon hitting eachother.
	world:register_event("PhysicsCollision", function(world, e1, e2, mtv)
		local v1, v2 = calculate_double_entity_pulse(e1, e2)

		e1.ColorIntensity = v1
		e2.ColorIntensity = v2
	end)
end

function sys_DrawEntity:process(e, dt)
	local world = self.world.world

	draw_entity_circle(e)

	if e.AimAngle then
		draw_entity_aiming(e)
	end

	restore_color_amp(e, dt)

	if world.DEBUG then
		draw_entity_debug_info(e)
	end
end
--- ==== ---

return Class(sys_DrawEntity)