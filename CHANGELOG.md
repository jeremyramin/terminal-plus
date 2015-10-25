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
