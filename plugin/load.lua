package.loaded["til_rewrite"] = nil
local tl = require("til_rewriter")
vim.api.nvim_create_user_command("TilRewrite", function(opts)
	local filepath = opts.args
	tl.rewrite_note(filepath)
end, { nargs = "?", complete = "file", desc = "Rewrite/refine a TIL or note with AI" })
