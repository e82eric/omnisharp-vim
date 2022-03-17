local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local ns_previewer = vim.api.nvim_create_namespace "telescope.previewers"
local d = {
	{ "c:\\src\\DecompileTest\\ConsoleApp1\\Class1.cs", "red", "#ff0000"  },
	{ "$metadata", "red", "#ff0000"  },
	{ "$metadata", "#00ff00", "Other" },
	{ "$metadata", "#0000ff", "Data" },
	{ "$metadata", "Rules", "Column" }
}
local s = 'Huey \n'..
'Dewey \n'..
'Louie'

-- local colors = function _G.colors(opts, data)
function _G.colors(opts, data)
	opts = opts or {}
	pickers.new(opts, {
		layout_strategy='vertical',
    layout_config = {
      width = 0.95,
			height = 0.95
    },
		prompt_title = "colors",
		finder = finders.new_table {
			results = data,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry[2],
					-- display = entry[1] .. ' ' .. entry[2],
					ordinal = entry[1] .. ' ' .. entry[2],
				}
			end
		},
		preview = opts.previewer,
		-- previewer = previewers.new_buffer_previewer {
		-- 	title = opts.preview_title,
		-- 	get_buffer_by_name = function(_, entry)
		-- 		return entry.value
		-- 	end,
		-- 	define_preview = function(self, entry)
		-- 		if entry.value[1] ~= "$metadata" then
		-- 			local p = entry.value[1]
		-- 			if p == nil or p == "" then
		-- 				return
		-- 			end
		-- 			conf.buffer_previewer_maker(p, self.state.bufnr, {
		-- 				bufname = self.state.bufname,
		-- 				winid = self.state.winid,
		-- 				preview = opts.preview,
		-- 			})
		-- 		else
		-- 			local bufnr = self.state.bufnr
		-- 			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
		-- 			-- local spl = entry.value[3]:gmatch("[^\r\n]+")
		-- 			local lines = {}
		-- 			vim.list_extend(lines, vim.split(entry.value[3], "\n"))
		-- 			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
		-- 			vim.api.nvim_buf_set_option(bufnr, "syntax", "cs")
		-- 			-- 	vim.api.nvim_buf_set_option(bufnr, "syntax", "cs")
		-- 			-- vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, spl)
		-- 			-- for str in entry.value[3]:gmatch("[^\r\n]+") do
		-- 			-- 	vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {str})
		-- 			-- 	vim.api.nvim_buf_set_option(bufnr, "syntax", "cs")
		-- 			-- end
		-- 		end
		-- 	end
		-- },
		sorter = conf.generic_sorter(opts),
		attach_mappings = opts.attach_mappings,
		-- attach_mappings = function(prompt_bufnr, map)
		-- 	actions.select_default:replace(function()
		-- 		local selection = action_state.get_selected_entry()
		-- 		print(selection.value[1])
		-- 		actions.close(prompt_bufnr)
		-- 		vim.cmd("edit " .. vim.fn.fnameescape(selection.value[1]))
		-- 	end)
		-- 	return true
		-- end,
	}):find()
end

-- colors(require("telescope.themes").get_dropdown{}, d)
