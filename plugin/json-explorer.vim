" Helper functions {{{1

function! s:compare_pos(x, y)
	if (a:x[1] < a:y[1])
		return -1
	elseif (a:x[1] > a:y[1])
		return 1
	else
		if a:x[2] < a:y[2]
			return -1
		elseif a:x[2] > a:y[2]
			return 1
		else
			return 0
		endif
	endif
endfunction

function! s:range_contains(range, start, end)
	return s:compare_pos(a:start, a:range) <= 0 && s:compare_pos(a:range, a:end) <= 0
endfunction

function! s:getpos(pos)
	if type(a:pos) == type([])
		if len(pos) == 2
			let [line, column] = a:pos
		elseif len(pos) == 4
			let [_, line, column, _] = a:pos
		else
			let [line, column] = [0, 0]
		endif
	else
		let [_, line, column, _] = getpos(a:pos)
	endif
	return [line, column]
endfunction

" }}}1

" Python {{{1

function! s:valid_json(str)
python <<EOF
import json, vim
try:
	j = json.loads(vim.eval("a:str"))
	pretty = json.dumps(j, indent=4, separators=(',', ': '))
	vim.command("let pretty = '%s'" % pretty)
except ValueError:
	vim.command("let pretty = 0")
EOF
return pretty
endfunction

" }}}1

" Main plugin functions {{{1

function! s:json_detect(pos)
	" Save current cursor position in case we jump around.
	let cursor_save = getpos()

	" Obtain line number and column
	let [original_line, original_column] = s:getpos(a:pos)

	" TODO: Use searchpair() to find surrounding [] and {}

	" Restore cursor position that was saved.
	call cursor(original_line, original_column)
endfunction

function! s:json_explorer(pos)
	let json = s:json_detect(a:pos)
	if type(json) == type([])
		let [startline, startcol, endline, endcol, pretty] = json
		call s:json_window(pretty)
	endif
endfunction

function! s:json_window(json)
	" For now, just assume contents is in the @j buffer...
	below new
	set buftype=nofile
	set filetype=javascript
	nnoremap <silent> <buffer> q :q<CR>
	call append(0, json)
endfunction

" }}}1

" Globally available functions {{{1

function! ComparePos(x, y)
	return s:compare_pos(a:x, a:y)
endfunction

function! ValidJson(s)
	return s:valid_json(a:s)
endfunction

" }}}1

nnoremap <silent> <C-l> :call <SID>json_explorer(".")<CR>
