function! s:python(buffer)
python <<EOF
import json, vim, collections
buf = "@" + vim.eval("a:buffer")
j = json.loads(vim.eval(buf))
pretty = json.dumps(j, indent=4, separators=(',', ': '))
#vim.current.buffer.append(pretty)
vim.command("let %s = '%s'" % (buf, pretty))
EOF
endfunction

function! s:find_bracket(pos)
	let buf_save = @j
	let @j = ''
	normal ?[[{]"jy%
	let json = @j
	let @j = buf_save
endfunction

function! s:json_detect()
	" Rudimentary attempt for now...
	let [ostartl, ostartc, oendl, oendc] = [-1, -1, -1, -1]
	normal v
	while 1
		normal a{
		let [a, startl, startc, b] = getpos("'<")
		let [a, endl, endc, b] = getpos("'>")
		if [ostartl, ostartc, oendl, oendc] == [startl, startc, endl, endc]
			break
		endif
		let [ostartl, ostartc, oendl, oendc] = [startl, startc, endl, endc]
	endwhile
	let buf_save = @j
	normal "jy
	call s:python('j')
	call s:json_window()
	let @j = buf_save
endfunction

function! s:json_window()
	" For now, just assume contents is in the @j buffer...
	below new
	set buftype=nofile
	set filetype=javascript
	nnoremap <buffer> q :q<CR>
	normal "jp
endfunction

nnoremap <C-l> :call <SID>json_detect()<CR>
