local _createFibGenerator
local simulateFibonacci
local main

local SequenceResult = {}
SequenceResult.__index = function(self, key)
	local getter = SequenceResult["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return SequenceResult[key]
end

SequenceResult.__newindex = function(self, key, value)
	local setter = SequenceResult["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function SequenceResult.new(sequenceName, data)
	local self = setmetatable({}, SequenceResult)

	self.sequenceName = sequenceName
	self.data = data
	self.generatedAt = os.date('%Y-%m-%d %H:%M:%S')

	return self
end

function SequenceResult:printSummary()
	print(`\`{self.sequenceName}\` Summary:\nGenerated: {self.generatedAt}\nData: [{table.concat({table.unpack(self.data)}, ', ')}]\nLength: {#self.data} items.\n___________________________________`)
end

function _createFibGenerator(max: number): any

	local a: number = 0

	local b: number = 1

	local function next(): number

		local nextValue: number = a + b

		a = b
		b = nextValue
		return a

	end

	return next

end

function simulateFibonacci(count: number)

	print("=== FIBONACCI GENERATOR WITH COMPLEX STATE ===\n")
	local gen: any = _createFibGenerator(count)

	local sequence: any = {}

	local i: number = 0

	while true do

		if i >= count then

			break
		end

		local result: number = gen()

		if result % 2 ~= 0 then

			i += 1
			continue
		end

		table.insert(sequence, result)
		i += 1
	end

	local finalResult: any = SequenceResult.new("Even Fibonacci", sequence)

	finalResult:printSummary()
end

function main()

	simulateFibonacci(10)
end

main()
