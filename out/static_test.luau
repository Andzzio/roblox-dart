local main

local Animal = {}
Animal.__index = Animal

function Animal.new()
	local self = setmetatable({}, Animal)


	return self
end

function Animal:makeContext()
end

local Person = setmetatable({}, Animal)
Person.__index = Person

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
