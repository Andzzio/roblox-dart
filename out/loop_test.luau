local function evenNumbers(limit: number)

	do

		local i: number = 0

		while i <= limit do

			if i % 2 == 0 then

				print(i)

			end

			i += 1

		end

	end

end

local function oddNumbers(limit: number)

	local i: number = 1

	while i <= limit do

		print(i)

		i += 2

	end

end

local function multiplesOf3(limit: number)

	local i: number = 1

	repeat

		if i % 3 == 0 then

			print(i)

		end

		i += 1

	until not (i <= limit)

end

local function listTest()

	local numbers: any = {1, 2, 3, 4, 5}

	for _, number in ipairs (numbers) do

		print(number)

	end

end

local function main()

	evenNumbers(10)

	oddNumbers(10)

	multiplesOf3(10)

	listTest()

end

main()

