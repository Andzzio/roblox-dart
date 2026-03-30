local score
local score

function get_score(): number

	return 100

end

function set_score(value: number)

	return print(`Setting score to {value}`)

end


local Exports = {
    get_score = get_score,
    set_score = set_score,
}
return Exports
