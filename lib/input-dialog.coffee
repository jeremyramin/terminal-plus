Dialog = require "./dialog"
os = require "os"

module.exports =
class InputDialog extends Dialog
  constructor: (@terminalView) ->
    super
      prompt: "Insert Text"
      iconClass: "icon-keyboard"
      stayOpen: true

  onConfirm: (input) ->
    if atom.config.get('platformio-ide-terminal.toggles.runInsertedText')
      eol = os.EOL
    else
      eol = ''

    data = "#{input}#{eol}"
    @terminalView.input data
    @cancel()
