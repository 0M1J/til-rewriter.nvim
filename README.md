-----
# til-rewriter.nvim
Neovim TIL Rewriter : AI based TIL (Today I Learned) rewriter. 

A Neovim plugin to help you refine and improve your Today I Learned (TIL) notes and other Markdown documents using AI.

This plugin allows you to send your Markdown content to an AI model (like OpenAI's GPT-4o) for rewriting, summarization, or style improvements, with options for custom system prompts and intelligent image handling. The AI-generated output is then presented in a new, temporary buffer for your review and saving.

-----

## Requirements

  * Neovim (v0.8.0 or later)
  * `curl` command-line tool
  * An API key for your chosen AI model (e.g., OpenAI API Key)

-----

## Installation

Install using `lazy.nvim` (recommended for Kickstart.nvim users):

1.  Place the `til_rewriter.lua` file in your Neovim configuration's plugin directory (e.g., `~/.config/nvim/lua/custom/plugins/`).

2.  Ensure your `init.lua` (or equivalent) enables loading of custom plugins. For Kickstart.nvim, uncomment or add `require("custom.plugins")`.

    Your `til_rewriter.lua` should look like this:

    ```lua
    -- ~/.config/nvim/lua/custom/plugins/til_rewriter.lua

    return {
      {
        '0M1J/til-rewriter.nvim',
        version = '*', -- recommended, use latest release instead of latest commit
        keys = {
            { "<leader>tr", "<cmd>TilRewrite<cr>", desc = "Rewrite TIL/Note with AI" },
        },
        
      },
    }
    ```

-----

## Setup

1.  **Set your API Key:**
    The plugin requires your AI API key to be set as a **system environment variable**.
    For OpenAI, set `OPENAI_API_KEY`.

    Add this to your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`):

    ```bash
    export OPENAI_API_KEY="sk-YOUR_SECRET_API_KEY_HERE"
    ```

    Remember to replace `sk-YOUR_SECRET_API_KEY_HERE` with your actual key and restart your terminal or `source` the file. The plugin will error out if this variable is not found.

-----

## Usage

### Command

```vim
:TilRewrite [filepath.md]
```

  * If `filepath.md` is provided, it processes that file.
  * `%` for current file

-----

## Examples

### 1\. Using the Default Prompt

If your Markdown file has no specific system prompt in its header, the plugin will use its intelligent default prompt to rewrite your TIL for clarity and conciseness.

**`my_til.md`:**

```markdown
# My First Neovim Plugin

I learned today that making Neovim plugins in Lua is quite different from Vimscript. It involves using `vim.api` functions and understanding `lazy.nvim` if you're using Kickstart. I found it a bit tricky at first, especially with the `return {}` part for `lazy.nvim`.
```

Run `:TilRewrite`. The AI will rewrite the note using the default style guide.

-----

### 2\. Using an Inline System Prompt

You can add a specific instruction for the AI directly in your Markdown file's header (within the first 20 lines).

**`my_prompted_note.md`:**

```markdown
systemprompt: "txt|Summarize this document into a single, concise paragraph focusing on the key challenges."

# Project X Challenges
The development of Project X faced numerous hurdles. One significant issue was the integration of legacy systems, which proved more complex than initially estimated due to undocumented APIs. Resource allocation was another challenge, as the team often found itself short-staffed for critical phases. Furthermore, securing external partnerships introduced unexpected delays, requiring extensive legal reviews.
```

Run `:TilRewrite`. The AI will summarize the content based on your inline prompt.
