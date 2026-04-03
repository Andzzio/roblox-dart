local main

local workspace = game:GetService("Workspace")
function main()

	local part = Instance.new("Part")

	part.Parent = workspace
	local connection = part.Touched:Connect(function(hit: any)
	print(hit.Name)
end)

	local connection2 = part.TouchEnded:Connect(function(hit: any)
	return print(hit.Name)

end)

	part.Touched:Once(function(hit: any)
	print(`touched once: {hit.Name}`)
end)
	part.Touched:Wait()
	connection:Disconnect()
	connection2:Disconnect()
end

main()
