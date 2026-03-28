local main

local Player = {}
Player.__index = function(self, key)
	local getter = Player["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Player[key]
end

Player.__newindex = function(self, key, value)
	local setter = Player["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Player.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Player"
end

function Player.new(namedArgs: any)
	local self = setmetatable({}, Player)

	local name = if namedArgs then namedArgs.name else nil
	assert(name ~= nil, "Parameter 'name' is required")
	local hp = if namedArgs then namedArgs.hp else nil
	assert(hp ~= nil, "Parameter 'hp' is required")
	self.name = name
	self.hp = hp
	self.isAlive = if self.hp > 0 then true else false

	return self
end

function Player:get_info()
	return `Name: {self.name},\nHP: {self.hp},\nIsAlive: {self.isAlive}`

end

function Player:takeDamage(damage)
	self.hp -= damage
	if self.hp < 0 then

		self.hp = 0
	end

	self.isAlive = if self.hp > 0 then true else false
end

function main()

	local player = Player.new({
		["name"] = "John Doe",
		["hp"] = 100,
	})

	print(player.info)
	player:takeDamage(50)
	print(player.info)
	player:takeDamage(50)
	print(player.info)
end

main()
