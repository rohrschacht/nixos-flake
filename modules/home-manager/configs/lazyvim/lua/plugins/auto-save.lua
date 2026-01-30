return {
  "okuuva/auto-save.nvim",
  lazy = false,
  opts = {
    debounce_delay = 500,
    noautocmd = true,
    -- execution_message = {
    --   message = function()
    --     return ""
    --   end,
    -- },
  },
  keys = {
    { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
  },
}
