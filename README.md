# 📱 r2nvim.nvim

## English 🇬🇧
Neovim plugin designed to integrate **Radare2** directly into your editor.

### Key Features
* **Direct Radare2 Integration:** Uses `radare2` backend.
* **Smart Formatter:** Automatic table alignment.
* **Navigation:** Quick jump to addresses via `GOTO`.

### Installation
```lua
{
    "egordebug/r2nvim.nvim",
    config = function()
        require("r2nvim").config.bin = "radare2"
    end
}
```

### Main Commands
* `:R2 Open <path>` — open a binary file.
* `:R2 Decompile <target>` — decompile function.
* `:R2 GOTO <addr>` — jump to address.

---

## Русский 🇷🇺
Плагин для Neovim, интегрирующий **Radare2** прямо в редактор.

### Основные возможности
* **Интеграция с Radare2:** Сила `r2` внутри вима.
* **Умный форматировщик:** Выравнивание таблиц.
* **Навигация:** Быстрый переход по `GOTO`.

### Установка
```lua
{
    "egordebug/r2nvim.nvim",
    config = function() end
}
```

### Основные команды
* `:R2 Open <путь>` — открыть файл.
* `:R2 Decompile <цель>` — декомпиляция.
* `:R2 GOTO <адрес>` — переход к адресу.

### Требования
* **Radare2** в PATH.

### License
MIT