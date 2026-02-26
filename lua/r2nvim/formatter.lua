local M = {}

function M.format_table(lines)
    local max_widths = {}
    local rows = {}
    
    for _, line in ipairs(lines) do
        local cols = {}
        for col in string.gmatch(line .. "|", "([^|]*)|") do
            table.insert(cols, col:gsub("^%s*(.-)%s*$", "%1"))
        end
        table.insert(rows, cols)
        for i, col in ipairs(cols) do
            max_widths[i] = math.max(max_widths[i] or 0, #col)
        end
    end

    local result = {}
    for _, row in ipairs(rows) do
        local formatted = ""
        for i, col in ipairs(row) do
            if i <= #max_widths then
                local padding = string.rep(" ", max_widths[i] - #col)
                formatted = formatted .. col .. padding .. " | "
            end
        end
        table.insert(result, formatted:gsub("%s*|%s*$", ""))
    end
    return result
end

return M
