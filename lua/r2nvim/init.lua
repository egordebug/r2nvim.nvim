local formatter = require('r2nvim.formatter')
local M = {}

M.config = {
    view = { "Addr", "Signature", "Asm", "Pseudo-C" },
    bin = "radare2",
}

M.buf = nil

function M.is_installed()
    local bin = M.config.bin
    if vim.fn.executable(bin) == 1 then
        return true
    end
    local msg = string.format("Error: '%s' not found in PATH. Please install '%s'.", bin, bin)
    vim.notify(msg, vim.log.levels.ERROR, { title = "r2nvim" })
    return false
end


local function get_lines_from_r2(r2_cmds)
    local file = vim.fn.expand('%:p')
    if file == "" then return {} end
    local cmd = string.format('%s -q -c "%s" "%s"', M.config.bin, r2_cmds, file)
    return vim.fn.systemlist(cmd)
end

function M.decompile(target)
    target = target or "main"
    local r2_cmds = string.format("aa; s %s; pdi", target)
    local output = get_lines_from_r2(r2_cmds)
    
    local table_data = {}
    for _, line in ipairs(output) do
        local addr, sig, instr = line:match("(0x%x+)%s+([%x%s]+)%s+(.*)")
        if addr then
            local row_parts = {}
            for _, v in ipairs(M.config.view) do
                if v == "Addr" then table.insert(row_parts, addr)
                elseif v == "Signature" then table.insert(row_parts, sig:sub(1,10))
                elseif v == "Asm" then table.insert(row_parts, instr)
                elseif v == "Pseudo-C" then table.insert(row_parts, "/* logic */")
                end
            end
            table.insert(table_data, table.concat(row_parts, "|"))
        end
    end

    local final_lines = formatter.format_table(table_data)
    
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(M.buf, 'ft', 'asm')
    end
    
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, final_lines)
    
    if vim.fn.bufwinid(M.buf) == -1 then
        vim.cmd('tabnew | b ' .. M.buf)
    end
end

function M.goto_addr(target)
    target = target or vim.fn.expand("<cword>")
    if target == "" then return end
    M.decompile(target)
end

function M.open_project(name)
    local file = vim.fn.expand('%:p')
    vim.fn.system(string.format('%s -q -c "Po %s" %s', M.config.bin, name, file))
    print("Project " .. name .. " loaded")
end

return M
