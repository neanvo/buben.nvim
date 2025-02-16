<div align="center">
  <h1>⭐️ Buben ⭐️</h1>
  <p><strong>Buben</strong> is a Neovim plugin designed to enhance the readability and management of blockchain addresses in your code. It allows you to assign human-readable names to blockchain addresses, displaying them inline or at the end of lines. This feature makes your blockchain-related code more maintainable and easier to understand.</p>
</div>

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Neovim](https://img.shields.io/badge/Neovim->=0.8.0-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## ✨ Features

- 🏷️ Assign custom names and chain identifiers to blockchain addresses
- 🔄 Toggle between inline and end-of-line display
- 🔍 Telescope integration for easy address management
- 💾 Persistent storage of address mappings
- 🎨 Customizable appearance with highlighting

## 📸 Examples

### Not Hovered Labels
![Not hovered](https://raw.githubusercontent.com/neanvo/buben.nvim/main/assets/non-hovered.png)

### Hovered Labels
![After](https://raw.githubusercontent.com/neanvo/buben.nvim/main/assets/hovered.png)

### Telescope Integration
![Telescope](https://raw.githubusercontent.com/neanvo/buben.nvim/main/assets/telescope.png)

## 📋 Requirements

- Neovim >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) >= 0.1.0

## 🚀 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "neanvo/buben.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    opts = {}
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "neanvo/buben.nvim",
    requires = { "nvim-telescope/telescope.nvim" },
    config = function()
        require("buben").setup()
    end
}
```

## ⚙️ Configuration

The plugin can be configured by passing a table to the setup function. Here's the complete configuration with all available options and their default values:

```lua
require("buben").setup({
    -- Path where address mappings will be stored
    storage_path = vim.fn.stdpath("data") .. "/buben_addresses.json",

    -- Popup window configuration for address input/editing
    popup = {
        -- Width of the input popup window
        width = 40,

        -- Border style for the popup window
        -- Possible values: "none", "single", "double", "rounded", "solid", "shadow"
        border = "rounded",
    },

    -- Enable/disable address concealment
    -- When true, the original address will be hidden and only the label will be shown
    conceal = true,

    -- Symbol used to point to the label
    -- Can be any string, including Unicode characters (e.g. "→", "⇒", "▶")
    arrow = "→",

    -- Enable/disable default highlight groups
    -- Set to false if you want to define all highlights manually
    use_default_highlights = true,
})
```

## 🎮 Usage

### Adding New Addresses

1. Place your cursor on a blockchain address (format: 0x...)
2. Call `:lua require("buben").add_address()`
3. Enter a name and chain identifier when prompted

### Managing Addresses

- Toggle visibility: `:lua require("buben").toggle_visibility()`
- Browse addresses: `:lua require("buben").open_telescope()`

#### Telescope Keybindings

| Key      | Action                                          |
|----------|------------------------------------------------|
| `<Enter>`| Copy address to clipboard                       |
| `<C-d>`  | Delete the selected address                    |
| `<C-e>`  | Edit name and chain of the selected address    |
| `<Esc>`  | Close Telescope window                         |

### Recommended Key Mappings

```lua
vim.keymap.set("n", "<leader>ba", require("buben").add_address, { desc = "Add blockchain address" })
vim.keymap.set("n", "<leader>bt", require("buben").toggle_visibility, { desc = "Toggle address visibility" })
vim.keymap.set("n", "<leader>bl", require("buben").open_telescope, { desc = "List addresses" })
```

## 🎨 Customization

### Highlight Groups

The plugin defines the following highlight groups:

- `BubenName`: Address name
- `BubenChain`: Chain identifier
- `BubenSeparator`: Separator elements
- `BubenTitle`: Popup title

### Default Colors

By default, the plugin sets up these highlight groups with predefined colors. You can:

1. Use the default highlights (default behavior)
2. Modify individual highlight groups
3. Disable all default highlights and define your own

#### Using Default Highlights

This is the default behavior, no additional configuration needed.

#### Modifying Individual Highlights

Override specific highlight groups while keeping others at default:

```lua
vim.api.nvim_set_hl(0, "BubenName", { fg = "#98c379", bg = "#565c64" })
vim.api.nvim_set_hl(0, "BubenChain", { fg = "#61afef", bg = "#565c64" })
```

#### Disabling Default Highlights

Disable default highlights in your setup:

```lua
require("buben").setup({
    use_default_highlights = false
})
```

Then define your own highlight groups:

```lua
-- Define all highlight groups manually
vim.api.nvim_set_hl(0, "BubenName", { fg = "#c678dd", bold = true })
vim.api.nvim_set_hl(0, "BubenChain", { fg = "#98c379", italic = true })
vim.api.nvim_set_hl(0, "BubenSeparator", { fg = "#565c64" })
vim.api.nvim_set_hl(0, "BubenTitle", { fg = "#e5c07b", bold = true })
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**neanvo**

- GitHub: [@neanvo](https://github.com/neanvo)
- Repository: [buben.nvim](https://github.com/neanvo/buben.nvim)

---

If you find this plugin useful, please consider giving it a ⭐️ on GitHub!
