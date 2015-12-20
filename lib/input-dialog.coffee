Dialog = require "./dialog"
os = require "os"

module.exports =
class InputDialog extends Dialog
  constructor: (@terminal) ->
    @focus = @terminal.isFocused()
    @terminal.blur()

    super
      prompt: "Insert Text"
      iconClass: "icon-keyboard"
      stayOpen: true

  onConfirm: (input) ->
    if atom.config.get('terminal-plus.toggles.runInsertedText')
      eol = os.EOL
    else
      eol = ''

    data = "#{input}#{eol}"
    @terminal.input data
    @cancel()

  cancel: ->
    @terminal.focus() if @focus
    super()
