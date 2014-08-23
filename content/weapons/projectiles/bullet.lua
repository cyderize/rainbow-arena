local proj_physical = require("content.weapons.projectiles.physical")

local weaputil = require("content.weapons.logic.weaputil")
local util = require("lib.self.util")

---

return function(radius, mass, damage)

	local proj = proj_physical(radius, mass)

	table.insert(proj.OnProjectileCollision, function(self, world, target, mtv)
		-- Damage entities hit by the bullet and destroy the bullet.
		if target.Health then
			target.Health = target.Health - damage
		end

		world:destroyEntity(self)
	end)

	return proj
end