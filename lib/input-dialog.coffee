{TextEditorView, View} = require 'atom-space-pen-views'

module.exports =
class InputDialog extends View
  @content: () ->
    @div class: 'terminal-plus input-dialog', =>
      @label 'Input', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @label 'Escape (Esc) to exit', style: 'float: left;'
      @label 'Enter (\u21B5) to accept', style: 'float: right;'

  initialize: (@terminalView) ->
    atom.commands.add @element,
      'core:confirm': =>
        @terminalView.input @miniEditor.getText().trim()
        @close()
      'core:cancel': => @cancel()

  attach: ->
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor.focus()
    @miniEditor.getModel().scrollToCursorPosition()

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()
    atom.workspace.getActivePane().activate()

  cancel: ->
    @close()
