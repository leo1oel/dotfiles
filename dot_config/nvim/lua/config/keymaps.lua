-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function open_popup(cmd)
  local ok, snacks = pcall(function()
    return Snacks
  end)
  if ok and snacks and snacks.terminal then
    snacks.terminal(cmd, {
      win = { position = "float", border = "rounded" },
    })
    return
  end
  vim.cmd("botright split | terminal " .. cmd)
end

vim.keymap.set("n", "V", function()
  open_popup("lazygit")
end, { desc = "LazyGit (Popup)" })

vim.keymap.set("n", "<leader>tv", function()
  vim.cmd("vsplit | terminal")
  vim.cmd("startinsert")
end, { desc = "Terminal Right" })

vim.keymap.set("n", "<leader>th", function()
  vim.cmd("split | terminal")
  vim.cmd("startinsert")
end, { desc = "Terminal Bottom" })
