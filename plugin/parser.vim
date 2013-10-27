function! s:parse(grammar, input, i)
	let [rule, data, name] = a:grammar
	if rule == "choice"
		for g in data
			try
				let [name, output, i] = s:parse(g, a:input, a:i)
				return [name, output, i]
			catch /Parse error/
				continue
			endtry
		endfor
	elseif rule == "sequence"
		let i = a:i
		let input = a:input
		let output = []
		for g in data
			let [sname, token, i] = s:parse(g, input, i)
			let output = add(output, [sname, token])
		endfor
		return [name, output, i]
	elseif rule == "class"
		let i = a:i
		if a:input[i] !~ '['.data.']'
			throw "Parse error"
		endif
		let c = a:input[i]
		let i = i + 1
		return [name, c, i]
	elseif rule == "terminal"
		let i = a:i
		if a:input[i] != data
			throw "Parse error"
		endif
		let c = a:input[i]
		let i = i + 1
		return [name, c, i]
	endif
endfunction
