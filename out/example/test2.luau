local div
local main

function div(a: number, b: number): number

	if b == 0 then

		return 0

	end

	return a / b

end

function main()

	local result: number = div(10, 2)

	print(result)
end

main()
