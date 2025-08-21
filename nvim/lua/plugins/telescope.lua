return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      vim.keymap.set("n", "<space>fh", require("telescope.builtin").help_tags, { desc = "Find Help Tags (Telescope)" })
      vim.keymap.set("n", "<space>ad", require("telescope.builtin").find_files, { desc = "Find Files (Telescope)" })
      vim.keymap.set(
        "n",
        "<space>ar",
        require("telescope.builtin").lsp_references,
        { desc = "LSP Rereferences (Telescope)" }
      )
    end,
  },
}
