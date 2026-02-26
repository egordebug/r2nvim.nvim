local r2 = require('r2nvim')

vim.api.nvim_create_user_command('R2', function(opts)
    if not r2.is_installed() then
        return
    end

    local args = vim.split(opts.args, " ")
    local cmd = args[1]

    if not cmd or cmd == "" then
        print("Usage: R2 <Command> [Args] (e.g., Decompile, Open, GOTO)")
        return
    end

    if cmd == "Open" then
        if args[2] then
            vim.cmd("edit " .. args[2])
        else
            print("Error: Path required for Open")
        end
    elseif cmd == "Decompile" then
        r2.decompile()
    elseif cmd == "GOTO" then
        r2.goto_addr(args[2])
    elseif cmd == "View-Set" then
        table.remove(args, 1)
        r2.config.view = args
        print("R2: View set to " .. table.concat(args, ", "))
    elseif cmd == "Save-Project" then
        local name = args[2] or "project"
        local file = vim.fn.expand('%:p')
        vim.fn.system(string.format('%s -q -c "Ps %s" %s', r2.config.bin, name, file))
        print("R2: Project '" .. name .. "' saved")
    elseif cmd == "Open-Project" then
        r2.open_project(args[2])
    end
end, {
    nargs = '*',
    complete = function()
        return {"Open", "Decompile", "GOTO", "View-Set", "Save-Project", "Open-Project"}
    end
})
