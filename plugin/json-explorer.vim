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
	let buf_save = @j
	let json = 0
	let [startline, startcol, endline, endcol] = [-1, -1, -1, -1]
	let cursor_save = getpos(".")
	let flags = 'bcW'
	let found = 0
	while search('[[{]', flags)
		let flags = 'bW'
		let @j = ''
		silent normal "jy%
		if @j == ''
			break
		endif
		let json = s:valid_json(@j)
		if type(json) == type(0)
			break
		endif
		let found = 1
		let [a, startline, startcol, b] = getpos("'[")
		let [a, endline, endcol, b] = getpos("']")
	endwhile
	let @j = buf_save
	if found == 0
		call cursor(cursor_save)
		return 0
	else
		return [startline, startcol, endline, endcol, json]
	endif
endfunction

function! ValidJson(s)
	return s:valid_json(a:s)
endfunction

function! s:json_explorer()
	let json = s:json_detect()
	if type(json) == type([])
		let [startline, startcol, endline, endcol, pretty] = json
		let buf_save = @j
		let @j = pretty
		call s:json_window()
		let @j = buf_save
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
	"let buf_save = @j
	"normal "jy
	"call s:python('j')
	"call s:json_window()
	"let @j = buf_save
"endfunction

function! s:json_window()
	" For now, just assume contents is in the @j buffer...
	below new
	set buftype=nofile
	set filetype=javascript
	nnoremap <buffer> q :q<CR>
	normal "jp
endfunction

nnoremap <C-l> :call <SID>json_explorer()<CR>
