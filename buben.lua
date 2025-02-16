---@type LazySpec
return {
    "neanvo/buben.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
        "BubenAdd",
        "BubenLookup",
        "BubenToggle",
    },
    dependencies = {
        "nvim-telescope/telescope.nvim",
    }
} 