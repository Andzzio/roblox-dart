local main

local Vector2D = {}
Vector2D.__index = function(self, key)
	local getter = Vector2D["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Vector2D[key]
end

Vector2D.__newindex = function(self, key, value)
	local setter = Vector2D["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function Vector2D.new(x, y)
	local self = setmetatable({}, Vector2D)

	self.x = x
	self.y = y

	return self
end

local Particle = {}
Particle.__index = function(self, key)
	local getter = Particle["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Particle[key]
end

Particle.__newindex = function(self, key, value)
	local setter = Particle["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function Particle.new(id, startX: number, startY: number, velocity)
	local self = setmetatable({}, Particle)

	self.id = id
	self.velocity = velocity
	self._position = Vector2D.new(startX, startY)
	Particle.totalParticles += 1

	return self
end

function Particle:get_position()
	return self._position

end

function Particle:set_position(newPos)
	self._position = newPos
end

function Particle:update(deltaTime)
	self._position.x += self.velocity.x * deltaTime
	self._position.y += self.velocity.y * deltaTime
end

Particle.totalParticles = 0
local BouncingParticle = setmetatable({}, Particle)
BouncingParticle.__index = function(self, key)
	local getter = BouncingParticle["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return BouncingParticle[key]
end

BouncingParticle.__newindex = function(self, key, value)
	local setter = BouncingParticle["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function BouncingParticle.new(id, startX, startY, velocity, bounds)
	local self = Particle.new(id, startX, startY, velocity)
	setmetatable(self, BouncingParticle)

	self.bounceCount = 0

	self.bounds = bounds

	return self
end

function BouncingParticle:update(deltaTime)
	Particle.update(self, deltaTime)
	local bounced: boolean = false

	if self.position.x > self.bounds or self.position.x < -self.bounds then

		self.velocity.x = -self.velocity.x
		bounced = true
	end

	if self.position.y > self.bounds or self.position.y < -self.bounds then

		self.velocity.y = -self.velocity.y
		bounced = true
	end

	if bounced then

		self.bounceCount += 1
		print(`\`{self.id}\` bounced!\nTotal bounces for this particle: {self.bounceCount}`)
	end

end

local PhysicsWorld = {}
PhysicsWorld.__index = function(self, key)
	local getter = PhysicsWorld["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return PhysicsWorld[key]
end

PhysicsWorld.__newindex = function(self, key, value)
	local setter = PhysicsWorld["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function PhysicsWorld.new()
	local self = setmetatable({}, PhysicsWorld)

	self._particles = {}


	return self
end

function PhysicsWorld:spawnParticle(p)
	table.insert(self._particles, p)
end

function PhysicsWorld:simulateStep(deltaTime)
	for i = 0, #self._particles - 1 do
		local particle = self._particles[i + 1]

		if particle.velocity.x == 0 and particle.velocity.y == 0 then

			continue
		end

		particle:update(deltaTime)
	end

end

function PhysicsWorld:printStatus()
	print("\n--- World Status ---")
	for i = 0, #self._particles - 1 do
		local p = self._particles[i + 1]

		print(`Particle \`{p.id}\` -> X: {p.position.x}, Y: {p.position.y}`)
	end

end

function main()

	print("=== 2D PHYSICS SIMULATION ===\n")
	local world = PhysicsWorld.new()

	world:spawnParticle(BouncingParticle.new("Alpha", 0.0, 0.0, Vector2D.new(10.0, 5.0), 20.0))
	world:spawnParticle(BouncingParticle.new("Beta", 18.0, 0.0, Vector2D.new(5.0, 0.0), 20.0))
	world:spawnParticle(BouncingParticle.new("Gamma", -5.0, -5.0, Vector2D.new(0.0, 0.0), 20.0))
	print("Simulating 3 steps...")
	for step = 1, 3 do
		print(`\nStep {step}:`)
		world:simulateStep(1.0)
	end

	world:printStatus()
	print(`\nTotal particles in memory: {Particle.totalParticles}`)
end

main()
