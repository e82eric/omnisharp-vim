if !OmniSharp#util#CheckCapabilities() | finish | endif

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:format_line(quickfix) abort
  return printf('%s: %d col %d     %s',
  \ a:quickfix.filename, a:quickfix.lnum, a:quickfix.col, a:quickfix.text)
endfunction

function! s:location_sink(str) abort
  for quickfix in s:quickfixes
    if s:format_line(quickfix) == a:str
      break
    endif
  endfor
  echo quickfix.filename
  call OmniSharp#locations#Navigate(quickfix)
endfunction

function! s:decomp_sink(str) abort
  for quickfix in s:quickfixes
    if s:format_line(quickfix) == a:str
      break
    endif
  endfor
  echo quickfix.filename
  if quickfix.filename == "$metadata"
    "call OmniSharp#actions#definition#FindFromMetadata(quickfix)
  else
    "call OmniSharp#locations#Navigate(quickfix)
  endif
endfunction

function! fzf#OmniSharp#FindSymbols(quickfixes) abort
  let s:quickfixes = a:quickfixes
  let symbols = []
  for quickfix in s:quickfixes
    call add(symbols, s:format_line(quickfix))
  endfor
  let fzf_options = copy(get(g:, 'OmniSharp_fzf_options', { 'down': '40%' }))
  call fzf#run(
  \ extend(fzf_options, {
  \ 'source': symbols,
  \ 'sink': function('s:location_sink')}))
endfunction

function! s:action_sink(str) abort
  if s:match_on_prefix
    let index = str2nr(a:str[0: stridx(a:str, ':') - 1])
    let action = s:actions[index]
  else
    let filtered = filter(s:actions, {i,v -> get(v, 'Name') ==# a:str})
    if len(filtered) == 0
      echomsg 'No action taken: ' . a:str
      return
    endif
    let action = filtered[0]
  endif
  if g:OmniSharp_server_stdio
    call OmniSharp#actions#codeactions#Run(action)
  else
    let command = substitute(get(action, 'Identifier'), '''', '\\''', 'g')
    let command = printf('runCodeAction(''%s'', ''%s'')', s:mode, command)
    let result = OmniSharp#py#Eval(command)
    if OmniSharp#py#CheckForError() | return | endif
    if !result
      echo 'No action taken'
    endif
  endif
endfunction

function! fzf#OmniSharp#GetCodeActions(mode, actions) abort
  let s:match_on_prefix = 0
  let s:actions = a:actions

  if has('win32')
    " Check whether any actions contain non-ascii characters. These are not
    " reliably passed to FZF and back, so rather than matching on the action
    " name, an index will be prefixed and the selected action will be selected
    " by prefix instead.
    for action in s:actions
      if action.Name =~# '[^\x00-\x7F]'
        let s:match_on_prefix = 1
        break
      endif
    endfor
    if s:match_on_prefix
      call map(s:actions, {i,v -> extend(v, {'Name': i . ': ' . v.Name})})
    endif
  endif

  let s:mode = a:mode
  let actionNames = map(copy(s:actions), 'v:val.Name')

  let fzf_options = copy(get(g:, 'OmniSharp_fzf_options', { 'down': '10%' }))
  call fzf#run(
  \ extend(fzf_options, {
  \ 'source': actionNames,
  \ 'sink': function('s:action_sink')}))
endfunction

function! fzf#OmniSharp#FindUsages(quickfixes, target) abort
  let s:quickfixes = a:quickfixes
  let usages = []
  for quickfix in s:quickfixes
    call add(usages, s:format_line(quickfix))
  endfor
  let fzf_options = copy(get(g:, 'OmniSharp_fzf_options', { 'down': '40%' }))
  call fzf#run(fzf#wrap(
  \ extend(fzf_options, {
  \ 'source': usages,
  \ 'sink': function('s:location_sink')})))
endfunction

function! fzf#OmniSharp#FindMembers(quickfixes, target) abort
  let s:quickfixes = a:quickfixes
  let usages = []
  for quickfix in s:quickfixes
    call add(usages, s:format_line(quickfix))
  endfor
  let fzf_options = copy(get(g:, 'OmniSharp_fzf_options', { 'down': '40%' }))
  call fzf#run(fzf#wrap(
  \ extend(fzf_options, {
  \ 'source': usages,
  \ 'sink': function('s:location_sink')})))
endfunction

function! fzf#OmniSharp#FindImplementations(quickfixes, target) abort
  let s:quickfixes = a:quickfixes
  let fzf_options = copy(get(g:, 'OmniSharp_fzf_options', { 'down': '40%' }))

  let g:t = []
  for q in a:quickfixes
    call add(g:t, [q.filename, q.text, get(q, 'sourcetext', ''), q])
  endfor
lua << EOF
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local previewers = require "telescope.previewers"
  local action_state = require "telescope.actions.state"
  local tmp = vim.g.t
  colors({
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
        if selection.value[1] == "$metadata" then
          actions.close(prompt_bufnr)
          vim.fn['OmniSharp#actions#definition#FindFromMetadata'](selection.value[4])
        else
          actions.close(prompt_bufnr)
          vim.cmd("edit " .. vim.fn.fnameescape(selection.value[4].filename))
					vim.fn.cursor(selection.value[4].lnum, selection.value[4].col)
        end
			end)
			return true
		end,
		previewer = previewers.new_buffer_previewer {
			get_buffer_by_name = function(_, entry)
				return entry.value
			end,
			define_preview = function(self, entry)
				if entry.value[1] ~= "$metadata" then
					local p = entry.value[1]
					if p == nil or p == "" then
						return
					end
					conf.buffer_previewer_maker(p, self.state.bufnr, {
						bufname = self.state.bufname,
						winid = self.state.winid,
						callback = function(bufnr)
							local currentWinId = vim.fn.bufwinnr(bufnr)
							if currentWinId ~= -1 then
								local metaObj = entry.value[4].metadata
								if metaObj ~= null then
									local startColumn = metaObj.StartColumn
									local endColumn = metaObj.EndColumn
									print("Column Info")
									print(startColumn)
									print(endColumn)
									print(entry.value[4].lnum)
									vim.api.nvim_buf_add_highlight(bufnr, -1, "TelescopePreviewLine", entry.value[4].lnum -1, startColumn, endColumn)
									vim.api.nvim_win_set_cursor(self.state.winid, { entry.value[4].lnum, 0 })
								end
							end
						end
					})
				else
          vim.fn['AsyncMetadata'](entry.value[4], self.state.bufnr, self.state.winid)
          vim.api.nvim_buf_set_option(self.state.bufnr, "syntax", "cs")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { 'Decompiling ' .. entry.value[2] .. '...'})
				end
			end
		},
  }, tmp)

  local M = {}

  function M.whatever()
    print("whatever called")
  end
EOF
endfunction

function! AsyncMetadata(metadata, bufnr, winid) abort
  let metadata = a:metadata
  let opts = { 'editcommand': 'edit', 'Initializing': 0 }
  let Cback = function('s:CBGotoDefinition', [opts])
  let Callback = function('s:CBMetadataFind', [Cback])
  call s:StdioMetadataFind(Callback, get(a:metadata, 'metadata'), a:bufnr, a:winid)
endfunction

function! s:StdioMetadataFind(Callback, metadata, bufnr, winid) abort
  let opts = {
  \ 'ResponseHandler': function('s:StdioMetadataFindRH', [a:Callback, a:metadata, a:bufnr, a:winid]),
  \ 'Parameters': a:metadata.MetadataSource,
  \ 'Initializing': 1
  \}
  call OmniSharp#stdio#Request('/metadata', opts)
endfunction

function! s:StdioMetadataFindRH(Callback, metadata, bufnr, winid, response) abort
  if !a:response.Success || a:response.Body.Source == v:null | return 0 | endif
  call a:Callback(a:response.Body, a:metadata, a:bufnr, a:winid)
endfunction

function! s:CBMetadataFind(Callback, response, metadata, bufnr, winid) abort
  let host = OmniSharp#GetHost()
  let lines = split(a:response.Source, "\n", 1)
  let lines = map(lines, {i,v -> substitute(v, '\r', '', 'g')})
  call setbufline(a:bufnr, 1, lines)
  call setbufvar(a:bufnr, 'syntax', 'cs')
  if exists("a:response.Line")
    let line=a:response.Line
    let column=a:response.Column
    let g:line=line
		let g:startCol = a:response.StartColumn
		let g:endCol = a:response.EndColumn
    let g:winid=a:winid
    let g:bufnr=a:bufnr
		let otherwinid = bufwinnr(a:bufnr)
		if otherwinid != -1
lua << EOF
	vim.api.nvim_buf_add_highlight(vim.g.bufnr, -1, "TelescopePreviewLine", vim.g.line -1, vim.g.startCol -1, vim.g.endCol -1)
  vim.api.nvim_win_set_cursor(vim.g.winid, { vim.g.line, 0 })
EOF
		endif
  endif
endfunction

function! s:CBGotoDefinition(opts, location, fromMetadata) abort
  if type(a:location) != type({}) " Check whether a dict was returned
    echo 'Not found'
    let found = 0
  else
    let found = OmniSharp#locations#Navigate(a:location, get(a:opts, 'editcommand', 'edit'))
    if found && a:fromMetadata
      setlocal nomodifiable readonly
    endif
  endif
  return found
endfunction
