-- ~/.config/nvim/lua/custom/plugins/til_rewriter.lua
-- Define your main plugin module
local M = {}

M.setup = function() end

-- Define the default system prompt as a multi-line string.
local DEFAULT_PROMPT = [[
You are an expert technical writer and editor specializing in creating clear, concise, and educational "Today I Learned" (TIL) entries. Your goal is to rewrite the provided content, ensuring it is highly readable and directly useful for a technical audience.

Analyze the input content and rewrite it to adhere to the following guidelines:

1.  **Clarity and Conciseness (Budget/Efficiency):**
    * Eliminate redundancy and unnecessary jargon.
    * Maintain a focused narrative that gets straight to the point.
    * Aim for a brief, impactful summary of the learned concept.

2.  **Accuracy and Grammar:**
    * Correct any grammatical errors, typos, or unclear phrasing.
    * Ensure the information is technically accurate based on the input.

3.  **Educational Structure:**
    * Present the core concept, the method (if applicable), and the outcome in a logical and easy-to-follow flow.
    * Use Markdown formatting (headings, lists, code blocks) appropriately to enhance readability.

4.  **Tone and Style (for the reader):**
    * Maintain a professional, informative, and engaging tone.
    * The final output should be suitable for sharing as a concise technical note or blog post.

Output only the rewritten Markdown content. Do not include any conversational filler or introductions.
]]

function M.rewrite_note(filepath)
	filepath = filepath or vim.api.nvim_buf_get_name(0)

	if not filepath or filepath == "" then
		vim.notify("No file specified and current buffer is not a file.", vim.log.levels.WARN)
		return
	end

	vim.notify("Processing file: " .. filepath, vim.log.levels.INFO)

	-- Read file content, extract prompt, handle images
	local lines = vim.fn.readfile(filepath)
	local content = table.concat(lines, "\n")

	local system_prompt = DEFAULT_PROMPT
	local current_content_without_images = content
	local image_suggestions_request = ""

	local header_scan_limit = 20 -- Scan first 20 lines for prompts
	local lines_to_process = vim.split(content, "\n")

	for i, line in ipairs(lines_to_process) do
		if i > header_scan_limit then
			break
		end

		-- System prompt from text
		local match_txt = string.match(line, '^systemprompt:%s*"txt%|(.-)"%s*$')
		if match_txt then
			system_prompt = match_txt
			current_content_without_images = string.gsub(current_content_without_images, line .. "\n?", "", 1)
			break
		end

		-- System prompt from file
		local match_file = string.match(line, '^systemprompt:%s*"file%|(.-)"%s*$')
		if match_file then
			local prompt_filepath = vim.fn.fnamemodify(filepath, ":h") .. "/" .. match_file
			local prompt_file_content = vim.fn.readfile(prompt_filepath)
			if #prompt_file_content > 0 then
				system_prompt = table.concat(prompt_file_content, "\n")
				current_content_without_images = string.gsub(current_content_without_images, line .. "\n?", "", 1)
			else
				vim.notify("System prompt file not found or empty: " .. prompt_filepath, vim.log.levels.WARN)
			end
			break
		end
	end

	-- Image handling (Option A: Extract and suggest)
	local image_pattern = [[!\[.*?\]\((.*?)\)]]
	local images_found = {}
	local temp_content_for_image_removal = current_content_without_images

	-- Remove image lines from content going to AI, collect them for suggestions
	current_content_without_images = string.gsub(temp_content_for_image_removal, image_pattern, function(match)
		table.insert(images_found, match)
		return "" -- Replace image markdown with empty string
	end)

	if #images_found > 0 then
		image_suggestions_request = "\n\n---IMAGE SUGGESTIONS---\n"
			.. "The original content contained images. Please suggest improved or alternative visualizations/diagrams for the following:\n"
			.. table.concat(images_found, "\n")
	end

	local final_prompt_for_ai = system_prompt .. "\n" .. current_content_without_images .. image_suggestions_request
	-- vim.notify("Content sent to AI:\n" .. final_prompt_for_ai, vim.log.levels.INFO) -- For debugging

	-- AI Integration (placeholder using curl with vim.fn.jobstart)
	M.send_to_ai(final_prompt_for_ai, function(generated_text)
		M.display_ai_output(generated_text, filepath)
	end)
end

function M.send_to_ai(prompt_text, callback)
	local api_key = os.getenv("OPENAI_API_KEY") or vim.g.til_rewriter_openai_api_key

	if not api_key then
		vim.notify(
			"OpenAI API key not set. Please set OPENAI_API_KEY environment variable or vim.g.til_rewriter_openai_api_key",
			vim.log.levels.ERROR
		)
		return
	end

	local headers = {
		"Content-Type: application/json",
		"Authorization: Bearer " .. api_key,
	}

	local body = vim.json.encode({
		model = "gpt-4o", -- Or your preferred model (e.g., "gemini-pro")
		messages = {
			{ role = "user", content = prompt_text },
		},
		max_tokens = 4000, -- Adjust based on expected output length
		temperature = 0.7, -- Adjust for creativity vs. faithfulness
	})

	local cmd = {
		"curl",
		"-s", -- Silent
		"-X",
		"POST",
		"-H",
		headers[1],
		"-H",
		headers[2],
		"-d",
		body,
		"https://api.openai.com/v1/chat/completions", -- OpenAI Chat Completions API endpoint
	}

	vim.notify("Sending content to AI...", vim.log.levels.INFO)

	vim.fn.jobstart(cmd, {
		on_stdout = vim.schedule_wrap(function(data)
			local response_table = vim.json.decode(data)
			-- --- ADD THESE LINES FOR DEBUGGING ---
			vim.notify("Raw AI Response (stdout):\n" .. data, vim.log.levels.INFO, { title = "Debug AI Response" })
			if data == "" then
				vim.notify("AI Response (stdout) was empty! Check curl command and network.", vim.log.levels.ERROR)
				return -- Stop processing if empty
			end
			if
				response_table
				and response_table.choices
				and response_table.choices[1]
				and response_table.choices[1].message
			then
				local generated_text = response_table.choices[1].message.content
				callback(generated_text)
			elseif response_table and response_table.error then
				vim.notify("AI API Error: " .. response_table.error.message, vim.log.levels.ERROR)
			else
				vim.notify("Unexpected AI API response format.", vim.log.levels.ERROR)
			end
		end),
		on_stderr = vim.schedule_wrap(function(data)
			vim.notify("Error from AI API (stderr): " .. table.concat(data), vim.log.levels.ERROR)
		end),
		on_exit = vim.schedule_wrap(function(code)
			if code ~= 0 then
				vim.notify("AI API job exited with code: " .. code, vim.log.levels.ERROR)
			end
		end),
	})
end

function M.display_ai_output(generated_text, original_filepath)
	local bufnr = vim.api.nvim_create_buf(true, true) -- true for listed, true for scratch
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(generated_text, "\n"))

	-- Open in a split window
	vim.cmd("vsplit") -- Or "split" for horizontal
	vim.api.nvim_set_current_buf(bufnr)
	vim.cmd("file [AI Rewritten] " .. vim.fn.fnamemodify(original_filepath, ":t"))
	vim.notify("AI rewrite complete! Review in new buffer.", vim.log.levels.INFO)
end

return M
