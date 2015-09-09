# Terminal-Plus
Terminal-Plus is a terminal package for Atom, complete with themes and more.  

![demo](/resources/demo.gif)

*[Nucleus Dark UI](https://atom.io/themes/nucleus-dark-ui) with [Atom Material Syntax](https://atom.io/themes/atom-material-syntax) and our **Homebrew** theme.*

## Usage
Terminal-Plus stays in the bottom of your editor while you work.

### Status Bar
![status-bar](/resources/status-bar.png)  
You can keep track of terminal instances via the status bar. Each new terminal is represented as a terminal icon in the bar.

The ( ![plus-icon](/resources/plus-icon.png) ) button creates a new terminal, while the ( ![red-x](/resources/red-x.png) ) button closes all terminals.  
Click on a status icon ( ![status icon](/resources/status-icon.png) ) to toggle that terminal. Right click the status icon for a list of available commands.  
From the right-click menu you can color code the status icon as well as hide or close the terminal instance.

### Terminal
You can toggle the terminal with the `terminal-plus:toggle` command (Default:`` ctrl-` ``). [See available commands below](#commands).  

From there you can begin typing into the terminal. By default the terminal will change directory into the project folder if possible. The default working directory can be changed in the settings to the home directory or to the active file directory.

## Features

### Full Terminal
Every terminal is loaded with your system’s default initialization files. This ensures that you have access to the same commands and aliases as you would in your standard terminal.

### Hackable
Plenty of settings for you to play with until your heart is content.

### Themes
The terminal is preloaded with several themes that you can choose from. Not satisfied?  
Use the following template in your stylesheet:
```css
.terminal-plus .xterm {
  background-color: ;
  color: ;

  ::selection {
    background-color: ;
  }

  .terminal-cursor {
    background-color: ;
  }
}
```

### Terminal Titles
By hovering over the terminal status icon, you can see which command is currently running in the terminal.

![](/resources/terminal_title.png)

### Color Coding
Need a faster way to figure out which terminal is which? Color code your status icons!

![](/resources/status-icon_color_coding.png)

### Sorting
Organize your open terminal instances by dragging and dropping them.

![sorting](/resources/sorting.gif)

## Install
Ready to install?

You can install via `apm`:

`apm install terminal-plus`

Or navigate to the install tab in Atom’s settings view, and search for `terminal-plus`.

## Commands
| Command | Action | Default Keybind |
|---------|--------|-----------------|
| terminal-plus:new | Create a new terminal instance. | `ctrl-shift-t` or `cmd-shift-t` |
| terminal-plus:toggle | Toggle the last active terminal instance.<br>**Note:** This will create a new terminal if it needs to. | `` ctrl-` `` (Control + Backtick) |
| terminal-plus:prev | Switch to the terminal left of the last active terminal. | `ctrl-shift-j` or `cmd-shift-j`
| terminal-plus:next | Switch to the terminal right of the last active terminal. | `ctrl-shift-k` or `cmd-shift-k`
