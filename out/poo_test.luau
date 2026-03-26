local main

local Entity = {}
Entity.__index = Entity

function Entity.new(name, namedArgs: any)
	local self = setmetatable({}, Entity)

	local hp = if namedArgs and namedArgs.hp ~= nil then namedArgs.hp else 100

	self.name = name

	self.hp = hp


	return self
end

function Entity.boss(name: string)
	local self = Entity.new(name, {
	["hp"] = 500,
})
	setmetatable(self, Entity)


	return self
end

function Entity:takeDamage(damage)
	self.hp -= damage

	print(`{self.name} received {damage} of damage. HP remaining: {self.hp}`)

end

local Player = setmetatable({}, Entity)
Player.__index = Player

function Player.new(name, namedArgs: any)
	local self = Entity.new(name, {
	["hp"] = 150,
})
	setmetatable(self, Player)

	local level = if namedArgs and namedArgs.level ~= nil then namedArgs.level else 1

	self.level = level


	return self
end

function Player:takeDamage(damage)
	print("The player is being attacked!")

	Entity.takeDamage(self, damage)

end

function Player:levelUp()
	self.level += 1

	print(`¡{self.name} subió al nivel {self.level}!`)

end

function main()

	local boss = Entity.boss("King Slime")

	local pro = Player.new("André", {
		["level"] = 10,
	})

	pro:takeDamage(20)

	boss:takeDamage(50)

	pro:levelUp()

end

main()
