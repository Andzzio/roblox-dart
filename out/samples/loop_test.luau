local evenNumbers
local oddNumbers
local multiplesOf3
local listTest
local fact
local main

function evenNumbers(limit: number)

	for i = 0, limit do
		if i % 2 == 0 then

			print(i)
		end

	end

end

function oddNumbers(limit: number)

	local i: number = 1

	while i <= limit do

		print(i)
		i += 2
	end

end

function multiplesOf3(limit: number)

	local i: number = 1

	repeat

		if i % 3 == 0 then

			print(i)
		end

		i += 1
	until not (i <= limit)

end

function listTest()

	local numbers: any = {
		1,
		2,
		3,
		4,
		5,
	}

	for _, number in ipairs(numbers) do

		print(number)
	end

end

function fact(namedArgs: any): number

	local max: number = if namedArgs and namedArgs.max ~= nil then namedArgs.max else 10
	if max == 0 then

		return 1

	end

	return max * fact({
	["max"] = max - 1,
})

end

function main()

	evenNumbers(10)
	oddNumbers(10)
	multiplesOf3(10)
	listTest()
	print(fact({
		["max"] = 5,
	}))
end

main()
