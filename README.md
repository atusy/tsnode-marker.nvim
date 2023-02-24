# tsnode-marker.nvim

Mark treesitter node to enhance context changes in your buffer.

## Demo

Change background colors of ...

- Markdown code blocks
- Nested functions

![demo](https://user-images.githubusercontent.com/30277794/221220876-3296c5e8-56c7-4ab7-9e91-e3b72340b39f.png)

## Install & Setup

With [folke/lazy.nvim](https://github.com/folke/lazy.nvim), and with an example setup to highlight markdown code blocks.

``` lua
require("lazy").setup({
  {
    "atusy/tsnode-marker.nvim",
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("tsnode-marker-markdown", {}),
        pattern = "markdown",
        callback = function(ctx)
          require("tsnode-marker").set_automark(ctx.buf, {
            target = { "code_fence_content" }, -- list of target node types
            hl_group = "CursorLine", -- highlight group
          })
        end,
      })
    end,
  },
}, {})
```

