local test = {}

local screenshake = require("lib.self.screenshake")
local util = require("lib.self.util")

local worldutil = require("util.world")
local circleutil = require("util.circle")
local colorutil = require("util.color")

local vector = require("lib.hump.vector")

---

local colliding = circleutil.colliding
local nelem = util.table.nelem

---

local PLAYER_RADIUS = 30

SOUND_POSITION_SCALE = 256

---

local world

function test:init()
	world = worldutil.new()
	world:load_system_dir("systems")
end

local function generate_position(radius)
	return vector.new(
		love.math.random(radius, world.w - radius),
		love.math.random(radius, world.h - radius)
	)
end

local function find_position(radius, tries)
	for try = 1, tries or 10 do
		local ok = true

		local pos = generate_position(radius)
		for entity in pairs(world:get_entities_with{"Position", "Radius"}) do
			if colliding(pos,radius, entity.Position,entity.Radius) then
				ok = false
				break
			end
		end

		if ok then return pos end
	end
end

-- https://stackoverflow.com/questions/667034/simple-physics-based-movement
local function calculate_drag_accel(max_speed, accel_time)
	local drag = 5/accel_time -- drag = 5/t_max
	local accel = max_speed * drag -- acc = v_max * drag
	return drag, accel
end

function test:enter(previous, w, h, nbots)
	world:clear_entities()

	world.w, world.h = w or 1000, h or 1000

	local c_drag, c_accel = calculate_drag_accel(800, 5)

	local proj = require("entities.projectiles.sticky_bomb"){

	}

	local weapon = require("entities.weapons.projectile"){
		max_heat = 3,
		shot_heat = 0.01,

		kind = "single",
		projectile = proj,
		projectile_speed = 300,
		shot_delay = 1,

		shot_sound = "audio/weapons/laser_shot.wav"
	}

	world:spawn_entity{
		Name = "Player",
		Team = "Player",

		Color = {0, 255, 255},

		Health = 30,
		MaxHealth = 30,

		Radius = PLAYER_RADIUS,
		Position = find_position(PLAYER_RADIUS),
		Velocity = vector.new(0, 0),
		Acceleration = vector.new(0, 0),

		Rotation = 0,
		RotationSpeed = 2,

		Drag = c_drag,
		MoveAcceleration = c_accel,

		CollisionPhysics = true,

		Weapon = weapon,

		Player = true,
		CameraTarget = true
	}

	-- Place test balls.
	for n = 1, 50 do
		local color = {colorutil.hsv_to_rgb(love.math.random(0, 359), 255, 255)}

		local radius = 30

		world:spawn_entity{
			Name = "Ball " .. n,

			Color = color,

			Health = 30,
			MaxHealth = 30,

			Radius = radius,
			Position = find_position(radius),
			Velocity = vector.new(0, 0),
			Acceleration = vector.new(0, 0),

			Drag = c_drag,
			MoveAcceleration = c_accel,

			CollisionPhysics = true
		}
	end
end

function test:update(dt)
	world:update(dt)
end

function test:draw()
	world:draw{
		ui = function(self)
			love.graphics.setColor(255, 255, 255)
			love.graphics.print("Speed multiplier: " .. self.speed, 10, 10)
			love.graphics.print(
				"Entities: " .. nelem(self.entities),
				10, 10 + love.graphics.getFont():getHeight()
			)
		end
	}
end


function test:keypressed(key, isrepeat)
	world:emit_event("KeyPressed", key, isrepeat)
end

function test:keyreleased(key)
	world:emit_event("KeyReleased", key)
end

function test:mousepressed(x, y, b)
	if b == "wd" then
		world.speed = world.speed - 0.1
	elseif b == "wu" then
		world.speed = world.speed + 0.1
	end

	world:emit_event("MousePressed", x, y, b)
end

function test:mousereleased(x, y, b)
	world:emit_event("MouseReleased", x, y, b)
end

return test
