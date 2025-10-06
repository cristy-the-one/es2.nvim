-- File: lua/es2/init.lua
local M = {}
local fzf_ok = pcall(require, "fzf-lua")

--- Setup function (can be extended for config)
function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend("force", {
    use_fzf = fzf_ok,
    exclude_extensions = { "exe", "dll" }, -- Extensions to exclude
    auto_open_single = true, -- Automatically open if only 1 result
  }, opts or {})

  if M.opts.use_fzf then
    local fzf_ok_check = pcall(require, "fzf-lua")
    if not fzf_ok_check then
      vim.notify("fzf-lua not found; falling back to quickfix", vim.log.levels.WARN)
      M.opts.use_fzf = false
    end
  end
end

--- Perform a file search using es and display results
--- @param query string: Search query (prompt if nil)
--- @param use_fzf boolean|nil: Override to use fzf-lua (if available)
function M.search(query, use_fzf)
  if not query or query == "" then
    vim.ui.input({ prompt = "ES Search: " }, function(input)
      if input and input ~= "" then
        M.search(input, use_fzf)
      end
    end)
    return
  end

  use_fzf = use_fzf or M.opts.use_fzf

  -- Run es command with full path
  local cmd = "es " .. vim.fn.shellescape(query) .. " -full-path-and-name"
  local output = vim.fn.systemlist(cmd)
  local shell_error = vim.v.shell_error

  if shell_error ~= 0 then
    vim.notify("Error running es: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end

  if #output == 0 then
    vim.notify("No results found for: " .. query, vim.log.levels.INFO)
    return
  end

  -- Process paths - es should return full Windows paths
  local lines = {}
  for _, line in ipairs(output) do
    -- Trim whitespace
    local trimmed = vim.trim(line)
    
    -- Skip empty lines and bare drive letters
    if trimmed ~= "" and not trimmed:match("^[A-Z]:$") then
      -- Normalize path separators to forward slashes for Neovim
      local normalized = trimmed:gsub("\\", "/")
      
      -- Check if file has excluded extension
      local is_excluded = false
      if M.opts.exclude_extensions then
        local ext = normalized:match("%.([^./]+)$")
        if ext then
          ext = ext:lower()
          for _, excluded_ext in ipairs(M.opts.exclude_extensions) do
            if ext == excluded_ext:lower() then
              is_excluded = true
              break
            end
          end
        end
      end
      
      -- Verify it's a valid Windows absolute path and not excluded
      if not is_excluded and normalized:match("^[A-Z]:/") then
        -- Check if file or directory exists
        if vim.fn.filereadable(normalized) == 1 or vim.fn.isdirectory(normalized) == 1 then
          table.insert(lines, normalized)
        end
      end
    end
  end

  -- Debug output
  vim.notify(
    string.format("ES found %d results, %d valid paths", #output, #lines),
    vim.log.levels.INFO
  )

  if #lines == 0 then
    vim.notify(
      "No valid file paths found. Raw output sample: " .. (output[1] or "empty"),
      vim.log.levels.WARN
    )
    return
  end

  if use_fzf and pcall(require, "fzf-lua") then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(lines, {
      prompt = string.format("ES [%s] > ", query),
      actions = {
        ["default"] = function(selected)
          for _, sel in ipairs(selected) do
            if vim.fn.isdirectory(sel) == 1 then
              -- Handle directory
              vim.cmd("cd " .. vim.fn.fnameescape(sel))
              local neo_ok, neo_tree = pcall(require, "neo-tree.command")
              if neo_ok then
                neo_tree.execute({
                  action = "focus",
                  source = "filesystem",
                  position = "left",
                  reveal = true,
                  dir = sel,
                })
              else
                vim.notify("Changed to directory: " .. sel, vim.log.levels.INFO)
              end
            else
              -- Handle file
              vim.cmd("edit " .. vim.fn.fnameescape(sel))
            end
          end
        end,
        ["ctrl-q"] = function(selected)
          -- Send to quickfix
          local qflist = {}
          for _, path in ipairs(selected) do
            table.insert(qflist, {
              filename = path,
              lnum = 1,
              col = 1,
              text = path,
            })
          end
          vim.fn.setqflist({}, " ", { title = "ES Search: " .. query, items = qflist })
          vim.cmd("copen")
        end,
      },
      previewer = "builtin",
      winopts = {
        height = 0.85,
        width = 0.80,
        preview = {
          hidden = false,
          wrap = true,
        },
      },
    })
  else
    -- Quickfix fallback
    local qflist = {}
    for _, path in ipairs(lines) do
      table.insert(qflist, {
        filename = path,
        lnum = 1,
        col = 1,
        text = path,
      })
    end
    vim.fn.setqflist({}, " ", { title = "ES Search: " .. query, items = qflist })
    vim.cmd("copen")
  end
end

return M
