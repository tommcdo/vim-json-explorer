function! s:valid_json(str)
python <<EOF
import json, vim
try:
	j = json.loads(vim.eval("a:str"))
	pretty = json.dumps(j, indent=4, separators=(',', ': '))
except ValueError:
	pretty = ''
vim.command("let pretty = '%s'" % pretty)
EOF
return pretty
endfunction

function! s:json_detect()
	let buf_save = @j
	let json = 0
	let [startline, startcol, endline, endcol] = [-1, -1, -1, -1]
	let cursor_save = getpos(".")
	while search('[[{]', 'bcW')
		let @j = ''
		silent normal "jy%
		if @j == ''
			echo "No string yanked"
			break
		endif
		let json = s:valid_json(@j)
		if json == ''
			echo "Invalid JSON: ".@j
			break
		endif
		echo "Valid JSON, it seems"
		let [a, startline, startcol, b] = getpos("'[")
		let [a, endline, endcol, b] = getpos("']")
	endwhile
	let @j = buf_save
	if [startline, startcol, endline, endcol] == [-1, -1, -1, -1]
		call cursor(cursor_save)
		return [-1, -1, -1, -1, '']
	else
		return [startline, startcol, endline, endcol, json]
	endif
endfunction

function! ValidJson(s)
	return s:valid_json(a:s)
endfunction

function! s:json_explorer()
	let json = s:json_detect()
	if json != [-1, -1, -1, -1, '']
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
