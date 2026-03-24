local function main()

	local hp: number = 100

	local damage: number = 25

	local finalHp: number = hp - damage

	print(`Player has {finalHp} HP`)

	local name: string = "Roblox"

	print(`{name} has {finalHp} HP`)

	print(finalHp)

end

main()

