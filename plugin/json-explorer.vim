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

function! s:json_detect()
	let reg_save = @j
	let json = 0
	let [startline, startcol, endline, endcol] = [-1, -1, -1, -1]
	let [_a, origline, origcol, _b] = getpos(".")
	let flags = 'bcW'
	let found = 0
	while search('[[{]', flags)
		let flags = 'bW'
		let @j = ''
		silent normal "jy%
		let [a, sline, scol, b] = getpos("'[")
		let [a, eline, ecol, b] = getpos("']")
		if @j == ''
			break
		endif
		if s:compare_position(origline, origcol, eline, ecol) < 0
			break
		endif
		let [startline, startcol, endline, endcol] = [sline, scol, eline, ecol]
		let json = s:valid_json(@j)
		if type(json) == type(0) && json == 0
			break
		endif
		let found = json
	endwhile
	"if s:compare_position(endline, endcol, origline, origcol) < 0
		"let found = 0
	"endif
	let @j = reg_save
	call cursor(origline, origcol)
	if type(found) == type(0) && found == 0
		return 0
	else
		return [startline, startcol, endline, endcol, found]
	endif
endfunction

function! s:compare_position(aline, acol, bline, bcol)
	if (a:aline < a:bline)
		return -1
	elseif (a:aline > a:bline)
		return 1
	else
		if a:acol < a:bcol
			return -1
		elseif a:acol > a:bcol
			return 1
		else
			return 0
		endif
	endif
endfunction

function! ValidJson(s)
	return s:valid_json(a:s)
endfunction

function! s:json_explorer()
	let json = s:json_detect()
	if type(json) == type([])
		let [startline, startcol, endline, endcol, pretty] = json
		let reg_save = @j
		let @j = pretty
		call s:json_window()
		let @j = reg_save
	endif
endfunction

"function! s:json_detect()
	"" Rudimentary attempt for now...
	"let [ostartl, ostartc, oendl, oendc] = [-1, -1, -1, -1]
	"normal v
	"while 1
		"normal a{
		"let [a, startl, startc, b] = getpos("'<")
		"let [a, endl, endc, b] = getpos("'>")
		"if [ostartl, ostartc, oendl, oendc] == [startl, startc, endl, endc]
			"break
		"endif
		"let [ostartl, ostartc, oendl, oendc] = [startl, startc, endl, endc]
	"endwhile
	"let reg_save = @j
	"normal "jy
	"call s:python('j')
	"call s:json_window()
	"let @j = reg_save
"endfunction

function! s:json_window()
	" For now, just assume contents is in the @j buffer...
	below new
	set buftype=nofile
	set filetype=javascript
	nnoremap <silent> <buffer> q :q<CR>
	normal "jp
endfunction

nnoremap <silent> <C-l> :call <SID>json_explorer()<CR>
