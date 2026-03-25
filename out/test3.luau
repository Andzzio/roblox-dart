local main
local executeOperation

function main()

	local salute = function(name: string)
		print(`Hello {name}`)

	end

	salute("André")

	local cuadrado = function(n: number)
		return n * n

	end

	print(cuadrado(5))

	executeOperation(10, 20, function(p0, p1)
		return p0 + p1

	end)

end

function executeOperation(a: number, b: number, operation: any)

	local result: number = operation(a, b)

	print(result)

end

main()
