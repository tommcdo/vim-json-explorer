let s:json_string = 
	\ ["object", [
		\ ["name", ["object", [
			\ ["first", ["string", "Tom"]],
			\ ["last", ["string", "McDonald"]],
		\ ]]],
		\ ["color", ["bare", "null"]],
		\ ["age", ["number", 25]],
		\ ["languages", ["array", [
			\ ["string", "PHP"],
			\ ["string", "JavaScript"],
			\ ["string", "VimL"]
		\ ]]]
	\ ]]

function! s:output_json(json, depth)
	let [type, data] = a:json

	let indent = repeat("\t", a:depth)
	let result = ""

	if type == "string"
		let result .= indent . "\"" . data . "\""
	elseif type == "number"
		let result .= indent . data
	elseif type == "bare"
		let result .= indent . data
	elseif type == "array"
		let result .= indent . "[" . "\n"
		for item in data
			let result .= s:output_json(item, a:depth + 1) . ",\n"
		endfor
		let result .= indent . "]"
	elseif type == "object"
		let result .= indent . "{\n"
		for [key, value] in data
			let result .= indent . "\t\"" . key . "\": "
			let result .= s:output_json(value, a:depth + 1) . ",\n"
		endfor
		let result .= indent . "}"
	endif

	return result
endfunction

function! Test()
	return s:output_json(s:json_string, 0)
endfunction
