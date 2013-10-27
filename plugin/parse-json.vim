let s:p_string = s:sequence(
	\ s:terminal('"'),
	\ s:choice_catchall(
		\ s:sequence(
			\ s:literal('\'),
			\ s:choice(
				\ s:sequence(s:literal('u'), s:repeat(s:class('a-z0-9'), 4)),
				\ s:class('"/\\bfnrt')
			\ )
		\ )
	\ ),
	s:terminal('"')
\ )

let s:p_number = s:sequence(
	s:optional(s:literal('-')),
	s:choice(
		... And so on
	\ )
\ )

let s:p_object = s:sequence(
	\ s:terminal('{'),
	\ s:sequence(
		s:sequence(s:p_string, s:terminal(':'), s:p_value)
	\ ),
	\ s:terminal('}')
\ )

let s:p_json = s:choice(
	\ s:p_object(),
	\ s:p_string()
\ )

function! s:choice(...)
	return ["choice", a:000]
endfunction

function! s:parse_json(input)
	if a:input[0] == '['
		let [result, i] = s:parse_array(a:input)
	elseif a:input[0] == '{'
		let [result, i] = s:parse_object(a:input)
	endif
	if i != strlen(a:input)
		throw 'Parse error'
	else
		return result
	endif
endfunction

function! s:parse_string(input, i)
	let i = a:i
	let token = a:input[i]
	let len = strlen(a:input)
	let i = i + 1
	while i < len
		if a:input[i] == '\'
			let token .= a:input[i]
			let i += 1
			if a:input[i] == 'u'
				let hex = a:input[(i):(i + 4)]
				if hex !~? '^u[a-f0-9]\{4}$'
					throw 'Parse error'
				endif
				let token .= hex
				let i += 4
			elseif a:input[i] =~ '["/\\bfnrt]'
				let token .= a:input[i]
			else
				throw 'Parse error'
			endif
		elseif a:input[i] == '"'
			let token .= a:input[i]
			break
		else
			let token .= a:input[i]
		endif
		let i += 1
	endwhile
	return [s:string(token), i]
endfunction

function! s:parse_number(input, i)
	let i = a:i
	let token = ''
	let len = strlen(a:input)
	if a:input[i] == '-'
		token .= a:token[i]
		let i = i + 1
	endif
	if a:input[i] =~ '[1-9]'
	elseif a:input[i] == '0'
	while i < len
		
	endwhile
endfunction

"This is NOT a valid unicode sequence: \u10FG"

function! Test(input)
	try
		echo s:parse_string(a:input)
	catch /^Parse error$/
		echo 'Parse error'
	endtry
endfunction

" {{{1
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
