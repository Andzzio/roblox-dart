local main

local Animal = {}
Animal.__index = function(self, key)
	local getter = Animal["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Animal[key]
end

Animal.__newindex = function(self, key, value)
	local setter = Animal["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Animal.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Animal"
end

function Animal.new()
	local self = setmetatable({}, Animal)


	return self
end

function Animal:makeContext()
end

local Person = setmetatable({}, Animal)
Person.__index = function(self, key)
	local getter = Person["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Person[key]
end

Person.__newindex = function(self, key, value)
	local setter = Person["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Person.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Person"
end

function Person.new(namedArgs: any)
	local self = setmetatable({}, Person)

	local name = if namedArgs then namedArgs.name else nil
	assert(name ~= nil, "Parameter 'name' is required")
	self.name = name
	Person.count += 1

	return self
end

function Person.singleton(name: string)
	return Person.new({
	["name"] = name,
})

end

function Person:makeContext()
	print(`Person: {self.name}, Species: {Person.species}`)
end

function Person.printCount()
	print(`Total People: {Person.count}`)
end

Person.species = "Human"
Person.count = 0
function main()

	local p = Person.new({
		["name"] = "André",
	})

	p:makeContext()
	Person.printCount()
	print(`Direct Static: {Person.species}`)
	local p2 = Person.singleton("Factory André")

	p2:makeContext()
end

main()
