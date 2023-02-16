# tsnode-marker.nvim

Mark treesitter node to enhance context changes in your buffer.

Typical usecase is to change background colors of markdown code blocks.

![demo](https://user-images.githubusercontent.com/30277794/219389779-2d7d62b9-138d-451f-ad82-d46a98f81eab.png)

## Install & Setup

With lazy, and with an example setup to highlight markdown code blocks.

``` lua
require("lazy").setup({
  {
    "atusy/tsnode-marker.nvim",
    lazy = true,
    filetype = "markdown",
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

