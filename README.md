## Author's Note
* Please make sure you are on the [latest version of Atom](https://atom.io/releases) before reporting bugs!
* This package requires that you have the dependencies for node-gyp.  
[See node-gyp install instructions](https://github.com/nodejs/node-gyp#installation).  
* You must use a monospaced font in order for the spacing to be right.

# Terminal-Plus
Terminal-Plus is a terminal package for Atom, complete with themes and more.  

![demo](https://github.com/jeremyramin/terminal-plus/raw/master/resources/demo.gif)

*[Nucleus Dark UI](https://atom.io/themes/nucleus-dark-ui) with [Atom Material Syntax](https://atom.io/themes/atom-material-syntax) and our Homebrew theme.*

## Usage
Terminal-Plus stays in the bottom of your editor while you work.

### Status Bar
![status-bar](https://github.com/jeremyramin/terminal-plus/raw/master/resources/status-bar.png)  
You can keep track of terminal instances via the status bar. Each terminal has a status icon ( ![status icon](https://github.com/jeremyramin/terminal-plus/raw/master/resources/status-icon.png) ) in the status bar. The ( ![plus-icon](https://github.com/jeremyramin/terminal-plus/raw/master/resources/plus-icon.png) ) button creates a new terminal, while the ( ![red-x](https://github.com/jeremyramin/terminal-plus/raw/master/resources/red-x.png) ) button closes all terminals.

Click on a status icon to toggle that terminal. Right click the status icon for a list of available commands. From the right-click menu you can color code the status icon as well as hide or close the terminal instance.

### Terminal
You can open the last active terminal with the `terminal-plus:toggle` command (Default:`` ctrl-` ``).  If no terminal instances are available, then a new one will be created. The same toggle command is used to hide the currently active terminal.

From there you can begin typing into the terminal. By default the terminal will change directory into the project folder if possible. The default working directory can be changed in the settings to the home directory or to the active file directory.

[See available commands below](#commands).

## Features

### Full Terminal
Every terminal is loaded with your system’s default initialization files. This ensures that you have access to the same commands and aliases as you would in your standard terminal.

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

### Process Titles
By hovering over the terminal status icon, you can see which command process is currently running in the terminal.

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/terminal_title.png)

### Terminal Naming
Need a faster way to figure out which terminal is which? Name your status icons!

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/status-icon_rename.png)

Available via the status icon context menu.

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/status-icon_rename-dialog.png)

### Color Coding
Color code your status icons!

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/status-icon_color_coding.png)

The colors are customizable in the settings, however the color names remain the same in the context menu.

### Sorting
Organize your open terminal instances by dragging and dropping them.

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/sorting.gif)

### Resizable
You can resize the view vertically, or just maximize it with the maximize button.

### Working Directory
You can set the default working directory for new terminals. By default this will be the project folder.

### File Dropping
Dropping a file on the terminal will insert the file path into the input. This works with external files, tabs from the Atom tab-view, and entries from the Atom tree-view.

### Quick Insert Command
Quickly insert and run selected text in your text editor by running the `terminal-plus:insert-selected-text` command (`ctrl-enter`).

![](https://github.com/jeremyramin/terminal-plus/raw/master/resources/insert_selected_text.gif)

If you have text selected, it will insert your selected text into the active terminal and run it.  
If you don't have text selected it, will run the text on the line where your cursor is then proceed to the next line.

## Install
Ready to install?

You can install via apm: `apm install terminal-plus`

Or navigate to the install tab in Atom’s settings view, and search for `terminal-plus`.

## Commands
| Command | Action | Default Keybind |
|---------|--------|-----------------|
| terminal-plus:new | Create a new terminal instance. | `ctrl-shift-t` or<br>`cmd-shift-t` |
| terminal-plus:toggle | Toggle the last active terminal instance.<br>**Note:** This will create a new terminal if it needs to. | `` ctrl-` ``<br>(Control + Backtick) |
| terminal-plus:prev | Switch to the terminal left of the last active terminal. | `ctrl-shift-j` or<br>`cmd-shift-j` |
| terminal-plus:next | Switch to the terminal right of the last active terminal. | `ctrl-shift-k` or<br>`cmd-shift-k` |
| terminal-plus:insert-selected-text | Run the selected text as a command in the active terminal. | `ctrl-enter` |

## TODO
- [x] Add support for status icon names
- [ ] Add support for terminal tabs
- [ ] Fix native module dependencies (pty.js)
- [ ] Improve performance for long running commands
- [ ] Add support for IME (Japanese characters)
