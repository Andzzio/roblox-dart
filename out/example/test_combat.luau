local main

local Character = {}
Character.__index = function(self, key)
	local getter = Character["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Character[key]
end

Character.__newindex = function(self, key, value)
	local setter = Character["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Character.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Character"
end

function Character.new(name: string, maxHealth: number)
	local self = setmetatable({}, Character)

	self._name = name
	self._maxHealth = maxHealth
	self._health = self._maxHealth
	Character.totalCharactersCreated += 1

	return self
end

function Character:get_name()
	return self._name

end

function Character:get_health()
	return self._health

end

function Character:get_isAlive()
	return self._health > 0

end

function Character:set_health(value)
	if value < 0 then

		self._health = 0
	elseif value > self._maxHealth then

		self._health = self._maxHealth
	else

		self._health = value
	end

end

function Character:takeDamage(amount)
	self.health -= amount
	print(`{self._name} took {amount} damage!\nRemaining HP: {self._health} / {self._maxHealth}`)
end

function Character.printGlobalStats()
	print(`Total characters spawned in the world: {Character.totalCharactersCreated}`)
end

Character.totalCharactersCreated = 0
local Warrior = setmetatable({}, Character)
Warrior.__index = function(self, key)
	local getter = Warrior["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Warrior[key]
end

Warrior.__newindex = function(self, key, value)
	local setter = Warrior["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Warrior.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Warrior"
end

function Warrior.new(name, maxHealth, armor)
	local self = Character.new(name, maxHealth)
	setmetatable(self, Warrior)

	self.inventory = {
		"Iron Sword",
		"Wooden Shield",
	}

	self.armor = armor

	return self
end

function Warrior:takeDamage(amount)
	local reducedDamage: number = amount - self.armor

	if reducedDamage < 0 then

		reducedDamage = 0
	end

	print(`\`{self.name}\` uses armor!\nBlocked {amount - reducedDamage} damage.`)
	Character.takeDamage(self, reducedDamage)
end

function Warrior:lootItem(item)
	table.insert(self.inventory, item)
	print(`{self.name} looted: {item}. Total items: {#self.inventory}`)
end

function main()

	print("=== RPG BATTLE SIMULATION ===\n")
	Character.printGlobalStats()
	local hero = Warrior.new("Arthur", 100, 5)

	local boss = Warrior.new("Dark Knight", 250, 10)

	print("\n--- Battle Starts ---")
	boss:takeDamage(30)
	hero:takeDamage(120)
	print("\n--- Battle Results ---")
	if not hero.isAlive then

		print(`Hero \`{hero.name}\` has fallen in battle...`)
	else

		print(`Hero \`{hero.name}\` survived!`)
	end

	hero:lootItem("Health Potion")
	print("\n")
	Character.printGlobalStats()
end

main()
