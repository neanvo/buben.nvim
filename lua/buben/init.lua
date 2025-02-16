local M = {}

M.version = "1.0.0"

---@class PopupConfig
---@field width number
---@field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"

---@class BubenConfig
---@field enabled boolean
---@field storage_path string
---@field popup PopupConfig
---@field conceal boolean
---@field arrow string
---@field use_default_highlights boolean
local DEFAULT_CONFIG = {
    enabled = true,
    storage_path = vim.fn.stdpath("data") .. "/buben_addresses.json",
    popup = {
        width = 40,
        border = "rounded",
    },
    conceal = true,
    arrow = "→",
    use_default_highlights = true,
}

---@class AddressInfo
---@field name string
---@field chain string

local NAMESPACE = 'buben_addresses'
local ADDRESS_PATTERN = "0x[a-fA-F0-9]+"

local UI = {
    colors = {
        name = { fg = "#98c379", bg = "#565c64" },
        chain = { fg = "#61afef", bg = "#565c64" },
        separator = { fg = "#b0b0b0", bg = "#565c64" },
        title = { fg = "#61afef", bold = true },
    }
}

local store = {
    ---@type table<string, AddressInfo>
    addresses = {},
    ns_id = vim.api.nvim_create_namespace(NAMESPACE),
    visible = true,
}

-- Health check function
function M.health()
    local health = require("health")
    health.report_start("buben.nvim")

    if vim.fn.has("nvim-0.8.0") == 1 then
        health.report_ok("Using Neovim >= 0.8.0")
    else
        health.report_error("Neovim >= 0.8.0 is required")
    end

    local has_telescope, _ = pcall(require, "telescope")
    if has_telescope then
        health.report_ok("telescope.nvim is installed")
    else
        health.report_error("telescope.nvim is required")
    end

    local storage_dir = vim.fn.fnamemodify(M.config.storage_path, ":h")
    if vim.fn.isdirectory(storage_dir) == 1 then
        health.report_ok("Storage directory exists")
    else
        health.report_warn("Storage directory does not exist: " .. storage_dir)
    end
end

M.info = {
    name = "buben.nvim",
    description = "Blockchain address substitution and management for Neovim",
    version = M.version,
    license = "MIT",
    author = "neanvo",
    repository = "https://github.com/neanvo/buben.nvim",
    dependencies = {
        ["telescope.nvim"] = ">=0.1.0",
    },
}

local function persist_addresses()
    local file = io.open(M.config.storage_path, "w")
    if not file then return end
    file:write(vim.json.encode(store.addresses))
    file:close()
end

local function load_persisted_addresses()
    local file = io.open(M.config.storage_path, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()
    local ok, data = pcall(vim.json.decode, content)
    if ok then store.addresses = data end
end

local function setup_ui_highlights()
    if M.config.use_default_highlights then
        vim.api.nvim_set_hl(0, "BubenName", UI.colors.name)
        vim.api.nvim_set_hl(0, "BubenChain", UI.colors.chain)
        vim.api.nvim_set_hl(0, "BubenSeparator", UI.colors.separator)
        vim.api.nvim_set_hl(0, "BubenTitle", UI.colors.title)
    end
end

local function format_label(info)
    return {
        {" " .. M.config.arrow .. " ", "BubenSeparator"},
        {info.name, "BubenName"},
        {" (", "BubenSeparator"},
        {info.chain, "BubenChain"},
        {") ", "BubenSeparator"},
    }
end

local function render_labels()
    if not store.visible then return end
    
    vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_clear_namespace(bufnr, store.ns_id, 0, -1)
        
        for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
            local start_idx = 1
            while true do
                local s, e = line:find(ADDRESS_PATTERN, start_idx)
                if not s then break end
                
                local address = line:sub(s, e)
                local info = store.addresses[address]
                if info then
                    vim.api.nvim_buf_set_extmark(bufnr, store.ns_id, lnum - 1, s - 1, {
                        end_col = e,
                        virt_text = format_label(info),
                        virt_text_pos = "inline",
                    })
                end
                start_idx = e + 1
            end
        end
    end)
end

local function create_input_window(title, on_submit)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winnr = vim.api.nvim_open_win(bufnr, true, {
        relative = "cursor",
        row = 1,
        col = 0,
        width = M.config.popup.width,
        height = 1,
        style = "minimal",
        border = M.config.popup.border,
        title = { { title, "BubenTitle" } },
    })
    
    vim.keymap.set("i", "<CR>", function()
        local content = vim.api.nvim_get_current_line()
        vim.api.nvim_win_close(winnr, true)
        if content ~= "" then on_submit(content) end
    end, { buffer = bufnr })

    vim.schedule(function() vim.cmd("startinsert") end)
end

function M.add_address()
    local word = vim.fn.expand('<cword>')
    if not word:match(ADDRESS_PATTERN) or store.addresses[word] then return end

    create_input_window("Enter name for " .. word, function(name)
        create_input_window("Enter chain for " .. word, function(chain)
            store.addresses[word] = { name = name, chain = chain }
            persist_addresses()
            render_labels()
            vim.cmd("stopinsert")
        end)
    end)
end

function M.toggle_visibility()
    store.visible = not store.visible
    if store.visible then
        render_labels()
    else
        vim.api.nvim_buf_clear_namespace(0, store.ns_id, 0, -1)
    end
end

function M.open_telescope()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local addresses = {}
    for addr, info in pairs(store.addresses) do
        table.insert(addresses, {
            address = addr,
            name = info.name,
            chain = info.chain
        })
    end

    local function delete_entry(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        store.addresses[selection.value.address] = nil
        persist_addresses()
        render_labels()
        
        local picker = action_state.get_current_picker(prompt_bufnr)
        local new_addresses = {}
        for addr, info in pairs(store.addresses) do
            table.insert(new_addresses, {
                address = addr,
                name = info.name,
                chain = info.chain
            })
        end
        
        picker:refresh(finders.new_table({
            results = new_addresses,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = string.format("%s (%s) ⸻ %s", entry.name, entry.chain, entry.address),
                    ordinal = entry.name .. entry.chain .. entry.address,
                }
            end,
        }), { reset_prompt = false })
    end

    local function edit_entry(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        actions.close(prompt_bufnr)
        create_input_window("Edit name for " .. selection.value.address, function(name)
            create_input_window("Edit chain for " .. selection.value.address, function(chain)
                store.addresses[selection.value.address] = {
                    name = name,
                    chain = chain
                }
                persist_addresses()
                render_labels()
                vim.cmd("stopinsert")
                
                M.open_telescope()
            end)
        end)
    end

    pickers.new({}, {
        prompt_title = "Ethereum Addresses",
        finder = finders.new_table({
            results = addresses,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = string.format("%s (%s) → %s", entry.name, entry.chain, entry.address),
                    ordinal = entry.name .. entry.chain .. entry.address,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<c-d>", function() delete_entry(prompt_bufnr) end)
            map("n", "<c-d>", function() delete_entry(prompt_bufnr) end)
            map("i", "<c-e>", function() edit_entry(prompt_bufnr) end)
            map("n", "<c-e>", function() edit_entry(prompt_bufnr) end)

            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                vim.fn.setreg("+", selection.value.address)
            end)
            return true
        end,
    }):find()
end

function M.setup(opts)
    if vim.fn.has("nvim-0.8.0") == 0 then
        error("buben.nvim requires Neovim >= 0.8.0")
    end

    M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
    if not M.config.enabled then return end

    setup_ui_highlights()
    load_persisted_addresses()

    -- Create commands with descriptions
    local commands = {
        BubenAdd = { M.add_address, "Add ETH address label" },
        BubenLookup = { M.open_telescope, "Lookup ETH addresses" },
        BubenToggle = { M.toggle_visibility, "Toggle address display" },
    }

    for name, cmd in pairs(commands) do
        vim.api.nvim_create_user_command(name, cmd[1], { desc = cmd[2] })
    end

    if M.config.conceal then
        vim.opt_local.conceallevel = 2
    end

    local augroup = vim.api.nvim_create_augroup("BubenVirtualText", { clear = true })
    vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost"}, {
        group = augroup,
        callback = render_labels,
        desc = "Update ETH address labels",
    })
end

return M 