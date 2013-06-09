" Line number that JSON output starts on
let s:start_line_number = 1

" Line number that s:output_json uses
let s:line_number = 1

" Paths to items
let s:line_pointer = {}

" Data element functions {{{1

function! s:element(type, value, args)
	let options = {
		\ "open": 1
	\ }
	call extend(options, get(a:args, 0, {}))
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

let s:json_object =
	\ s:object([
		\ ["name", s:object([
			\ ["first", s:string("Tom")],
			\ ["second", s:string("McDonald")]
		\ ], {"open": 1})],
		\ ["color", s:null()],
		\ ["age", s:number("25")],
		\ ["languages", s:array([
			\ s:string("PHP"),
			\ s:string("JavaScript"),
			\ s:string("VimL")
		\ ], {"open": 1})]
	\ ])

function! s:next_key(path)
	let path = a:path
	let len = len(path)
	let path[len - 1] += 1
	return path
endfunction

function! s:append_key(path)
	return a:path + [0]
endfunction

function! s:get_path(path)
	let pointer = s:json_object
	for step in a:path
		if pointer[0] == "object"
			let pointer = pointer[1][step][1]
		elseif pointer[0] == "array"
			let pointer = pointer[1][step]
		else
			throw "No good"
		endif
	endfor
	return pointer
endfunction

function! s:set_option(path, key, value)
	let pointer = s:get_path(a:path)
	let pointer[2][a:key] = a:value
endfunction

function! s:reset_line()
	let s:line_number = s:start_line_number
endfunction

function! s:newline()
	let s:line_number += 1
	return "\n"
endfunction

function! s:output_json(json, ...)
	let [type, data, options] = a:json

	let path = []
	if a:0 >= 1
		let path = a:1
	endif

	let depth = 0
	if a:0 >= 2
		let depth = a:2
	endif
	let is_obj = 0
	if a:0 >= 3
		let is_obj = a:3
	endif

	call s:set_option(path, 'line', s:line_number)
	let s:line_pointer[s:line_number] = path

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
		if options.open
			let result .= "[" . s:newline()
			let datalength = len(data)
			let counter = 1
			let path = s:append_key(path)
			for item in data
				let result .= s:output_json(item, path, depth + 1)
				if counter != datalength
					let result .= ","
				endif
				let counter += 1
				let result .= s:newline()
				let path = s:next_key(path)
			endfor
			let result .= indent . "]"
		else
			let result .= "[...]"
		endif
	elseif type == "object"
		if options.open
			let result .= "{" . s:newline()
			let datalength = len(data)
			let counter = 1
			let path = s:append_key(path)
			for [key, value] in data
				let result .= indent . "\t\"" . key . "\": "
				let result .= s:output_json(value, path, depth + 1, 1)
				if counter != datalength
					let result .= ","
				endif
				let counter += 1
				let result .= s:newline()
				let path = s:next_key(path)
			endfor
			let result .= indent . "}"
		else
			let result .= "{...}"
		endif
	endif

	return result
endfunction

function! s:get_element(line)
	return s:get_path(s:line_pointer[a:line])
endfunction

" Global functions for testing {{{1

function! Test()
	call s:reset_line()
	below new
	set buftype=nofile
	set filetype=javascript
	nnoremap <silent> <buffer> q :q<CR>
	nnoremap <silent> <buffer> o :echo <SID>get_element(getpos(".")[1])<CR>
	call append(0, split(s:output_json(s:json_object), "\n"))
endfunction

function! TestRaw()
	return s:json_object
endfunction

" }}}1

" vim: fdm=marker:
