" Data element functions {{{1

function! s:element(type, value, options)
	let options = {
		\ "open": 0
	\ }
	if type(a:options) == type({})
		for key in keys(a:options)
			let options[key] = a:options[key]
		endfor
	endif
	return [a:type, a:value, options]
endfunction

function! s:object(value, ...)
	return s:element("object", a:value, a:000)
endfunction

function! s:array(value, ...)
	return s:element("array", a:value, a:000)
endfunction

function! s:string(value, ...)
	return s:element("string", a:value, a:000)
endfunction

function! s:number(value, ...)
	return s:element("number", a:value, a:000)
endfunction

function! s:true(...)
	return s:element("bare", "true", a:000)
endfunction

function! s:false(...)
	return s:element("bare", "false", a:000)
endfunction

function! s:null(...)
	return s:element("bare", "null", a:000)
endfunction

" }}}1

let s:json_string =
	\ s:object([
		\ ["name", s:object([
			\ ["first", s:string("Tom")],
			\ ["second", s:string("McDonald")]
		\ ])],
		\ ["color", s:null()],
		\ ["age", s:number("25")],
		\ ["languages", s:array([
			\ s:string("PHP"),
			\ s:string("JavaScript"),
			\ s:string("VimL")
		\ ])]
	\ ])

function! s:output_json(json, ...)
	let [type, data, options] = a:json
	let depth = 0
	if a:0 >= 1
		let depth = a:1
	endif
	let is_obj = 0
	if a:0 >= 2
		let is_obj = a:2
	endif

	let indent = repeat("\t", depth)
	let result = ""

	if ! is_obj
		let result .= indent
	endif

	if type == "string"
		let result .= "\"" . data . "\""
	elseif type == "number"
		let result .= data
	elseif type == "bare"
		let result .= data
	elseif type == "array"
		let result .= "[" . "\n"
		let datalength = len(data)
		let counter = 1
		for item in data
			let result .= s:output_json(item, depth + 1)
			if counter != datalength
				let result .= ","
			endif
			let counter += 1
			let result .= "\n"
		endfor
		let result .= indent . "]"
	elseif type == "object"
		let result .= "{\n"
		let datalength = len(data)
		let counter = 1
		for [key, value] in data
			let result .= indent . "\t\"" . key . "\": "
			let result .= s:output_json(value, depth + 1, 1)
			if counter != datalength
				let result .= ","
			endif
			let counter += 1
			let result .= "\n"
		endfor
		let result .= indent . "}"
	endif

	return result
endfunction

function! Test()
	return s:output_json(s:json_string, 0)
endfunction

" vim: fdm=marker:
