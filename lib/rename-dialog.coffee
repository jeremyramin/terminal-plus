{$, TextEditorView, View} = require 'atom-space-pen-views'

module.exports =
class RenameDialog extends View
  @content: () ->
    @div class: 'terminal-plus-rename-dialog', =>
      @label 'Rename', class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)

  initialize: (@statusIcon) ->
    atom.commands.add @element,
      'core:confirm': =>
        @statusIcon.updateName @miniEditor.getText().trim()
        @close()
      'core:cancel': => @cancel()
    @miniEditor.on 'blur', => @close()
    @miniEditor.getModel().setText @statusIcon.getName()
    @miniEditor.getModel().selectAll()

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
