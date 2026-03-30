local main

function main()

	local hp: number = 100

	local damage: number = 25

	local finalHp: number = hp - damage

	local isAlive: boolean = if finalHp > 0 then true else false

	print(`Player has {finalHp} HP`)
	local name: string = "Roblox"

	print(`{name} has {finalHp} HP`)
	if finalHp > 50 and isAlive then

		print("Left more than 50 HP and alive")
	elseif finalHp <= 50 and finalHp > 25 and isAlive then

		print("Left less than 50 HP and more than 25 HP and alive")
	elseif finalHp <= 25 and isAlive then

		print("Left less than 25 HP and alive")
	else

		print("Player is dead")
	end

	print(finalHp)
end

main()
