## 2.6.0 - PlatformIO

* Add predawn theme (#296)
* Optional --login shell (#294)
* Toolbar button with atom styleguide (#345)
* Fix labels rendering outside of Atom's 'editor mini' panel (#339)
* Fix "Some installed packages could not be loaded..." with a new Atom 1.19

## 2.5.5 - PlatformIO

* Add compatibility for Atom 1.19

## 2.5.4 - PlatformIO

* Updated One Dark theme foreground color to match Atom
* Fixed deprecation warning thrown in Atom Beta >=1.13

## 2.5.3 - PlatformIO

* Fix broken "Terminal: Focus" command

## 2.5.2 - PlatformIO

* Fix issue when opened terminal steals focus after focusing Atom

## 2.5.1 - PlatformIO

* Fix for delta calculation in resizePanel
* Fix focus (ctrl+alt+F) shortcut behavior

## 2.5.0 - PlatformIO

* New PlatformIO IDE Terminal API Provider
* Load terminal after Atom shell-environment is loaded
* Fix status bar alignment problem on native-ui theme

## 2.4.0 - PlatformIO

* Add terminal focus command and keybinding
* Fix issue when running `electron` command

## 2.3.1 - PlatformIO

* Use /bin/bash shell by default if process.env.SHELL is not defined

## 2.3.0 - PlatformIO

* New option: Copy text to clipboard on selection (enabled by default)

## 2.2.3 - PlatformIO

* Add Christmas and One-Dark themes
* Add compatibility for Atom 1.14 and Windows x64

## 2.2.2 - PlatformIO

* Fix "Uncaught TypeError: Cannot read property 'focus' of null" ([issue #29](https://github.com/platformio/platformio-atom-ide-terminal/issues/29))

## 2.2.1 - PlatformIO

* Add compatibility for Atom 1.12, Windows and macOS

## 2.2.0 - PlatformIO

* Add Solarized-Dark theme
* Make `insert-custom-text` context aware

## 2.1.1 - PlatformIO

* Change "red-x" to default Atom theme
* Move the status bar icons to the left of the file path

## 2.1.0 - PlatformIO

* Add Linux theme
* Presets with the custom commands/texts (`Settings > Custom Texts`)

## 2.0.10 - PlatformIO

* Add fullscreen command

## 2.0.9 - PlatformIO

* Fix PTY.js binary finder for Windows

## 2.0.8 - PlatformIO

* Rewrite PTY.js installer for NodeJS 0.10.x

## 2.0.7 - PlatformIO

* Update PTY.js dependency

## 2.0.6 - PlatformIO
* Improve foreground installation of PTY.js

## 2.0.5 - PlatformIO
* Add hook for node-gyp with pre-built binaries

## 2.0.4 - PlatformIO
* Switch to PlatformIO PTY.js fork

## 2.0.3 - PlatformIO
* Extend API with getTerminalViews

## 2.0.2 - PlatformIO
* Add API that allows any package to make a terminal, pass it a command and see the output
* Use Atom's native status bar instead own (save space)
* Use direct HTTP links to dependent packages instead `git+https`

## v0.14.5 - Patch
* Fix key-presses deselecting lines from the terminal
* Add alt-(arrow) and alt-(click) for moving cursor in terminal
* Improve `clear` command handling
* Make sure initial height is to the nearest row

## v0.14.4 - Patch
* Fix `reset` and `clear` command issues
* Improve `cmd-k` clear command
* Insert text as a command by default
* Match text editor font family for consistency
* Add font size setting back
* Destroy panel on terminal destroy
* Allow any css value for default panel height

## v0.14.3 - Patch
* Remove extra logs
* Bug fixes
* Match Atom's font size

## v0.14.2 - Patch
* Bring back default selection process
* Improvements to terminal (jeremyramin/term.js)
* Fix several bugs
* Clean up menus

## v0.14.1 - Patch
* Recompile binaries for Atom 1.2.0
* Fix focus error
* Return focus to terminal on window focus
* Minor fixes to text area and terminal resizing

## v0.14.0 - Beta Release
* Added support for non-English characters
 * Thanks to @yoshiokatsuneo for [his work](https://github.com/jeremyramin/term.js/commit/e851ea232a114902ea6a8e5cc8f7d34d07969c42).
 * Dead keys now work in the terminal
 * CJK (IME) should now work in the terminal
* Keep terminals maximized on new terminal view
* Improve terminal title handling
* Fix fullscreen not focusing
* Refactor dialog classes
* Update Windows binaries

## v0.13.1 - Patch
* Only run inserted text if `Run Inserted Text` is enabled
* Improve terminal title handling
  * Make sure the terminal title does not stay behind on new title
* Open the correct project folder for the active file
* Post-install clean-up script for pty.js (see issue #71)

## v0.13.0 - Beta Release
* Add support for alt+key combinations
* Right alt for escape sequences
* Fix terminal mapping toggle error when `Auto Open a New Terminal` is false
* Improve cursor:
  * Preserve the color of the character the cursor is over
  * Fix terminal cursor background-color being overwritten
* Only intercept ctrl+key combinations if ctrl is the only key being pressed

## v0.12.5 - Patch
* Fix `ctrl` key intercepting to ignore `ctrl-shift` combinations
* Fix `ctrl-s` pausing terminal on Linux systems

## v0.12.4 - Patch
* Map terminals while the active terminal is hidden
* Fix prev/next terminal switch
* Improve cursor blink animation
* New commands:
 * terminal-plus:close-all for closing all terminals
 * terminal-plus:rename for renaming the active terminal

## v0.12.3 - Patch
* Blur terminal window on window blur
* Adjust default ANSI colors for terminal
* Confirm that the active terminal is not null

## v0.12.2 - Patch
* Prevent terminal from intercepting alt+(key) events
  * Fixes broken copy and paste on Linux and Windows

## v0.12.1 - Patch
* Make sure status icon tooltip dismisses when the status icon is detached
* Fix copy and pasting bug with tabs
* Improve active terminal system
* Fix terminal resizing removing lines

## v0.12.0 - Beta Release
* Clean up tooltip
* Prevent file path insertion for empty file paths (Atom tabs)
* Add experimental support for tab view

## v0.11.2 - Patch
* Fix tooltips staying after the terminal has been closed

## v0.11.1 - Patch
* Fix broken links in README

## v0.11.0 - Beta Release
* Add insert text dialog for inserting special characters and running commands
  * Users can enable `Run Inserted Text` in the settings to have Terminal-Plus run inserted text as a command
  * Users can use the insert text dialog to type special characters
* Center terminal lines in the terminal-view
* Improved terminal mapping
* Improve terminal view focusing
  * Do not steal focus for the cursor blink
  * Do not steal focus for text input

## v0.10.1 - Patch
* Fix resizing bug
* Fix language overwrite bug

## v0.10.0 - Beta Release
* Added automatic terminal switching
* Add CMD+K to clear terminal [Term.js fork]
* Fix terminal errors relating to Atom setting project path to `atom://config`

## v0.9.1 - Patch
* Fix bug where Atom rebuilds Terminal-Plus for every update
* Fix status icon colors keypath

## v0.9.0 - Beta Release
* Add support for custom ANSI color set
* Fix `ctrl+c` (SIGINT) not working in bash
* Update winpty module (for Windows) in pty.js
* Fix issues with maintaining focus on the terminal

## v0.8.2 - Patch
* Detect system language on OS X
* Even finer scrolling algorithm implemented

## v0.8.1 - Patch
* Disable double click on status icons

## v0.8.0 - Beta Release
* Implement finer scrolling in dependencies

## v0.7.1 - Patch
* Block resize and input when there is no pty process to message

## v0.7.0 - Beta Release
* Add support for international characters
* Make sure to declare the terminal as xterm-256color
* Improve colors in xterm-256color
* Set TERM_PROGRAM to Terminal-Plus

## v0.6.5 - Patch
* Focus bug fix

## v0.6.4 - Patch
* Fix terminal not scrolling for zsh shell with plugins

## v0.6.3 - Patch
* Call super after overriding focus
* Update the author's note with Windows 10 fix

## v0.6.2 - Patch
* Fix path variable overwrite bug

## v0.6.1 - Patch
* Fix text-wrap overflow hiding prompt

## v0.6.0 - Beta Release
* Dynamic terminal view resizing

## v0.5.1 - Patch
* Remove trailing whitespace from terminal rename

## v0.5.0 - Beta Release
* Add terminal naming via the status icon

## v0.4.3 - Patch
* Rebuild pty.js binaries for electron release 0.30.6
* Requires Atom >= 1.0.12

## v0.4.2 - Patch
* Specify commit for pty.js prebuilt

## v0.4.1 - Patch
* Make button toolbar smaller by keeping buttons minimal
  * No more names next to button
  * Make button fit to icon
* Use --login shell argument by default for bash and zsh

## v0.4.0 - Beta Release
* Add prebuilt binaries for pty.js
* Better support for systems without the tools needed to compile (Windows)

## v0.3.1 - Patch
* Add warning for custom font family (must use monospaced font)

## v0.3.0 - Beta Release
* Refactor resizing to snap to row
* Fix cursor line being removed if blank
* Possible fix for refresh error
* Fix for improper resizing when displaying the terminal for the first time

## v0.2.0 - Beta Release
* Bump up to minor version 2
* New settings and features added
* Bug fixes listed below in v0.1.x patches

## v0.1.10 - Patch
* Add option to auto close terminal on shell process exit

## v0.1.9 - Patch
* Add insert selected text (see commit)
* Remove login command

## v0.1.8 - Patch
* Remove quiet option from login
* Disable resize and input on terminal exit

## v0.1.7 - Patch
* Resize terminal on maximize and minimize
* Fix powershell.exe resolve
* Fix shell launch bugs

## v0.1.6 - Patch
* Make sure to properly resize terminal on open

## v0.1.5 - Patch
* On shell process exit, disable input to prevent error

## v0.1.4 - Patch
* Make terminal scroll to bottom on input
* Don't close the terminal view on process exit

## v0.1.3 - Patch
* Add more features to README.md
* Fix issue #1

## v0.1.2 - Patch
* Absolute image source paths in README.md
 * Update image in color coding section

## v0.1.1 - Patch
* Update the README.md and CHANGELOG.md

## v0.1.0 - Beta Release
* Initial release
