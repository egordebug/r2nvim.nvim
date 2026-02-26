local M = {}

M.config = {
    view = { "Addr", "Asm", "Pseudo-C" },
    bin = "radare2",
}

M.buf = nil

function M.is_installed()
    local bin = M.config.bin
    if vim.fn.executable(bin) == 1 then
        return true
    end
    local msg = string.format("Error: '%s' not found. Please install radare2.", bin)
    vim.notify(msg, vim.log.levels.ERROR, { title = "r2nvim" })
    return false
end

local function get_lines_from_r2(r2_cmds, on_done)
    local file = vim.fn.expand('%:p')
    if file == "" then 
        vim.notify("No file open", vim.log.levels.WARN)
        return 
    end
    
    local cmd = string.format('%s -q -c "%s" "%s"', M.config.bin, r2_cmds, file)
    local lines = {}
    
    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            for _, line in ipairs(data) do
                if line ~= "" then table.insert(lines, line) end
            end
        end,
        on_stderr = function(_, data)
            for _, line in ipairs(data) do
                if line ~= "" and line:match("^[IW]") then 
                    vim.api.nvim_echo({{ "[R2]: " .. line, "WarningMsg" }}, false, {})
                end
            end
        end,
        on_exit = function()
            on_done(lines)
        end
    })
end

function M.decompile(target)
    if not target or target == "" then
        target = vim.fn.expand("<cword>")
    end
    if not target or target == "" then
        target = "main"
    end
    target = target:gsub("%%", "") 

    local r2_cmds = string.format("e bin.cache=true; e bin.relocs.apply=true; s %s; af; pdi", target)
    
    vim.notify("R2: Analyzing " .. target .. "...", vim.log.levels.INFO)

    get_lines_from_r2(r2_cmds, function(output)
        local raw_table = {}
        
        table.insert(raw_table, table.concat(M.config.view, "|"))
        
        local sep = {}
        for _ in ipairs(M.config.view) do table.insert(sep, "---") end
        table.insert(raw_table, table.concat(sep, "|"))

        for _, line in ipairs(output) do
            local addr, rest = line:match("(0x%x+)%s+(.*)")
            if addr then
                local row = {}
                for _, v in ipairs(M.config.view) do
                    if v == "Addr" then table.insert(row, addr)
                    elseif v == "Asm" then table.insert(row, rest:gsub("%s+", " "))
                    else table.insert(row, " ") end
                end
                table.insert(raw_table, table.concat(row, "|"))
            end
        end

        vim.schedule(function()
            if #raw_table <= 2 then
                vim.notify("R2: No code found at " .. target, vim.log.levels.ERROR)
                return
            end

            local input_str = table.concat(raw_table, "\n")
            local final_lines = vim.fn.systemlist("column -t -s '|' -o ' | '", input_str)
            
            if vim.v.shell_error ~= 0 then
                vim.notify("Column error: check util-linux", vim.log.levels.ERROR)
                return
            end
            
            if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
                M.buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_option(M.buf, 'ft', 'asm')
                vim.api.nvim_buf_set_name(M.buf, "R2_Decompile")
            end

            vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, final_lines)
            
            if vim.fn.bufwinid(M.buf) == -1 then
                vim.cmd('vsplit | b ' .. M.buf)
            end
        end)
    end)
end

function M.goto_addr(target)
    target = target or vim.fn.expand("<cword>")
    if target ~= "" then M.decompile(target) end
end

function M.open_project(name)
    local file = vim.fn.expand('%:p')
    vim.fn.system(string.format('%s -q -c "Po %s" %s', M.config.bin, name, file))
    print("Project " .. name .. " loaded")
end

return M
