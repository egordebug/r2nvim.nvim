local M = {}

M.config = {
    view = { "Addr", "Asm", "Pseudo-C" },
    bin = "radare2",
}

M.buf = nil

function M.is_installed()
    return vim.fn.executable(M.config.bin) == 1
end

local function get_lines_from_r2(r2_cmds, on_done)
    local file = vim.fn.expand('%:p')
    if file == "" then return end
    local cmd = string.format('%s -n -q -c "%s" "%s"', M.config.bin, r2_cmds, file)
    local lines = {}
    
    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            for _, line in ipairs(data) do
                if line ~= "" then table.insert(lines, line) end
            end
        end,
        on_exit = function()
            on_done(lines)
        end
    })
end

function M.decompile(target)
    if not target or target == "" then target = vim.fn.expand("<cword>") end
    if not target or target == "" then target = "main" end
    target = target:gsub("%%", ""):gsub("%s+", "")
    local r2_cmds = string.format("e bin.cache=true; s %s; pdi 100", target)
    
    vim.notify("R2: Quick jump to " .. target, vim.log.levels.INFO)

    get_lines_from_r2(r2_cmds, function(output)
        local raw_table = {}
        table.insert(raw_table, table.concat(M.config.view, "|"))
        
        local sep = {}
        for _ in ipairs(M.config.view) do table.insert(sep, "---") end
        table.insert(raw_table, table.concat(sep, "|"))

        for _, line in ipairs(output) do
            local addr, rest = line:match("(0x%x+)%s+(.*)")
            if addr then
                local row = { addr, rest:gsub("%s+", " "), " " }
                table.insert(raw_table, table.concat(row, "|"))
            end
        end

        vim.schedule(function()
            if #raw_table <= 2 then
                vim.notify("R2: Nothing at " .. target, vim.log.levels.WARN)
                return
            end

            local input_str = table.concat(raw_table, "\n")
            local final_lines = vim.fn.systemlist("column -t -s '|' -o ' | '", input_str)
            
            if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
                M.buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_option(M.buf, 'ft', 'asm')
                vim.api.nvim_buf_set_name(M.buf, "R2_Disasm")
            end

            vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, final_lines)
            
            if vim.fn.bufwinid(M.buf) == -1 then
                vim.cmd('vsplit | b ' .. M.buf)
            end
        end)
    end)
end

function M.goto_addr(target)
    M.decompile(target)
end

return M
