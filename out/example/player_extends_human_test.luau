local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local inheritance_crossfile_test = _RD.import(script, "inheritance_crossfile_test")
local Human = inheritance_crossfile_test.Human

local Player = setmetatable({}, Human)
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

function Player.new(name, age)
	local self = Human.new(name, age)
	setmetatable(self, Player)


	return self
end

function Player:greet()
	print(`Hello, I am {self.name} and I am {self.age} years old.`)
end

function main()

	local p = Player.new("André", 19)

	p:greet()
end

main()
