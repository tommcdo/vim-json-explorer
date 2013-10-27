" Line number that JSON output starts on
let s:start_line_number = 1

" Line number that s:output_json uses
let s:line_number = 1

" Paths to items
let s:line_pointer = {}

" Data element functions {{{1

function! s:element(type, value, args)
	let options = {
		\ "open": 0
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
			\ ["first", s:string('Thomas "Tom"')],
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

function! s:next_key(path)
	let path = a:path
	let len = len(path)
	let path[len - 1] += 1
	return path
endfunction

function! s:append_key(path)
	return a:path + [0]
endfunction

function! s:remove_key(path)
	if a:path == []
		return 0
	else
		return a:path[:-2]
	endif
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
	let s:line_pointer = {}
	let s:line_number = s:start_line_number
endfunction

function! s:newline()
	let s:line_number += 1
	return "\n"
endfunction

function! s:escape_string(string)
	return substitute(a:string, '"', '\\"', 'g')
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

	let line_number = s:line_number
	let pointer = s:get_path(path)
	let pointer[2]['line'] = line_number
	let pointer[2]['parent_path'] = s:remove_key(path)
	if path != []
		let pointer[2]['key'] = path[-1]
	endif
	let s:line_pointer[line_number] = pointer

	let indent = repeat("\t", depth)
	let result = ""

	if ! is_obj
		let result .= indent
	endif

	if type == "string"
		let result .= "\"" . s:escape_string(data) . "\""
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
			let s:line_pointer[s:line_number] = line_number
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
			let s:line_pointer[s:line_number] = line_number
		else
			let result .= "{...}"
		endif
	endif

	return result
endfunction

function! s:redraw(line)
	call s:reset_line()
	set modifiable
	%d
	call append(s:start_line_number - 1, split(s:output_json(s:json_object), "\n"))
	$d
	set nomodifiable
	echo ''
	call cursor(a:line, 0)
endfunction

function! s:get_line_number(args)
	if len(a:args) > 0
		if type(a:args[0]) == type(0)
			let line = a:args[0]
		elseif type(a:args[0]) == type([])
			let line = a:args[0][1]
		else
			let line = getpos(a:args[0])[1]
		endif
	else
		let line = getpos(".")[1]
	endif
	return line
endfunction

function! s:get_line_pointer(line)
	let line = a:line
	let pointer = s:line_pointer[line]
	while type(pointer) == type(0)
		let line = pointer
		unlet pointer
		let pointer = s:line_pointer[line]
	endwhile
	return [line, pointer]
endfunction

function! s:toggle_open(...)
	let line = s:get_line_number(a:000)
	let [line, pointer] = s:get_line_pointer(line)
	if pointer[0] == "array" || pointer[0] == "object"
		let pointer[2].open = 1 - pointer[2].open
		call s:redraw(line)
	endif
endfunction

function! s:close_parent(...)
	let line = s:get_line_number(a:000)
	let [line, pointer] = s:get_line_pointer(line)
	if type(pointer[2].parent_path) == type([])
		let parent = s:get_path(pointer[2].parent_path)
		let parent[2].open = 0
		call s:redraw(parent[2].line)
	endif
endfunction

function! s:change_key(...)
	let line = s:get_line_number(a:000)
	let [line, pointer] = s:get_line_pointer(line)
	if type(pointer[2].parent_path) == type([])
		let parent = s:get_path(pointer[2].parent_path)
		if parent[0] == "object"
			let position = pointer[2].key
			let newkey = input("Enter new key value: ", parent[1][position][0])
			let parent[1][position][0] = newkey
			call s:redraw(line)
		endif
	endif
endfunction

" Global functions for testing {{{1

function! Test()
	below new
	set buftype=nofile
	set filetype=javascript
	set cursorline
	setlocal nomodifiable
	nnoremap <silent> <buffer> q :q<CR>
	nnoremap <silent> <buffer> o :<C-u>call <SID>toggle_open()<CR>
	nnoremap <silent> <buffer> x :<C-u>call <SID>close_parent()<CR>
	nnoremap <silent> <buffer> ck :<C-u> call <SID>change_key()<CR>
	call s:redraw(1)
endfunction

function! TestRaw()
	return s:json_object
endfunction

" }}}1

" vim: fdm=marker:
