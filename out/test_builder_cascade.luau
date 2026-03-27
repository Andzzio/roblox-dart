local main

local ItemRarity
do
	local _mt = {
		__tostring = function(self) return self._name end
	}
	local function _create(cname, index)
		local obj = { index = index, name = cname, _name = "ItemRarity." .. cname }
		setmetatable(obj, _mt)
		table.freeze(obj)
		return obj
	end

	ItemRarity = {}
	ItemRarity.common = _create("common", 0)
	ItemRarity[0] = ItemRarity.common
	ItemRarity.rare = _create("rare", 1)
	ItemRarity[1] = ItemRarity.rare
	ItemRarity.epic = _create("epic", 2)
	ItemRarity[2] = ItemRarity.epic
	ItemRarity.legendary = _create("legendary", 3)
	ItemRarity[3] = ItemRarity.legendary

	table.freeze(ItemRarity)
end

local Modifier = {}
Modifier.__index = function(self, key)
	local getter = Modifier["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Modifier[key]
end

Modifier.__newindex = function(self, key, value)
	local setter = Modifier["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function Modifier.new(name, multiplier)
	local self = setmetatable({}, Modifier)

	self.name = name
	self.multiplier = multiplier

	return self
end

local Weapon = {}
Weapon.__index = function(self, key)
	local getter = Weapon["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Weapon[key]
end

Weapon.__newindex = function(self, key, value)
	local setter = Weapon["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function Weapon.forged(name, baseDamage, rarity)
	local self = setmetatable({}, Weapon)

	self.statBonuses = {}

	self.name = name
	self.baseDamage = baseDamage
	self.rarity = rarity

	return self
end

function Weapon:applyModifier(mod)
	self.activeModifier = mod
	print(`Applied modifier: {mod.name} (x{mod.multiplier})`)
end

function Weapon:addBonus(stat, value)
	self.statBonuses[stat] = ((function() local _v = self.statBonuses[stat]; if _v ~= nil then return _v else return 0 end end)()) + value
end

function Weapon:calculateDamage()
	local mult: number = (function() local _v = (function() local _v = self.activeModifier; if _v ~= nil then return _v.multiplier else return nil end end)(); if _v ~= nil then return _v else return 1.0 end end)()

	return math.floor((self.baseDamage * mult))

end

local Player = {}
Player.__index = function(self, key)
	local getter = Player["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Player[key]
end

Player.__newindex = function(self, key, value)
	local setter = Player["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

function Player.new(username)
	local self = setmetatable({}, Player)

	self.username = username

	return self
end

function Player:equip(w)
	self.equippedWeapon = w
	print(`\n{self.username} equipped \`{w.name}\`!`)
end

function Player:attack()
	local dmg: number = (function() local _v = (if self.equippedWeapon ~= nil then self.equippedWeapon:calculateDamage() else nil); if _v ~= nil then return _v else return 0 end end)()

	if dmg > 0 then

		print(`{self.username} attacks for {dmg} damage!`)
	else

		print(`{self.username} punches the air helplessly...`)
	end

end

function main()

	print("=== FORGE & CASCADE TEST ===")
	local noob = Player.new("Andzzio")

	noob:attack()
	local epicSword = (function()
		local _c = Weapon.forged("Dragon Blade", 50, ItemRarity.epic)
		_c:applyModifier(Modifier.new("Fire Aspect", 1.5))
		_c:addBonus("STR", 10)
		_c:addBonus("AGI", 5)
		return _c
end)()

	noob:equip(epicSword)
	noob:attack()
	print("\n--- Weapon Details ---")
	print(`Rarity: {epicSword.rarity.name}`)
	print("Bonuses:")
		for _k, _v in pairs(epicSword.statBonuses) do
		(function(key, value)
			print(`	+ {value} to {key}`)
		end)(_k, _v)
	end

end

main()
