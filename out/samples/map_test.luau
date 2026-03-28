local main

function main()

	local map: any = {
		["name"] = "Andre",
		["age"] = 19,
		["isStudent"] = true,
		["courses"] = {
			"Physics 1",
			"Data Structures",
			"Math Discrete",
		},
	}

	print(map["name"])
	print(map["age"])
	print(map["isStudent"])
	for _, course in pairs(map["courses"]) do

		print(course)
	end

end

main()
