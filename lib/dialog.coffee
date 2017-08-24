{TextEditorView, View} = require 'atom-space-pen-views'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'platformio-ide-terminal-dialog', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @label 'Escape (Esc) to exit', style: 'width: 50%;'
      @label 'Enter (\u21B5) to confirm', style: 'width: 50%; text-align: right;'

  initialize: ({iconClass, placeholderText, stayOpen} = {}) ->
    @promptText.addClass(iconClass) if iconClass
    atom.commands.add @element,
      'core:confirm': => @onConfirm(@miniEditor.getText())
      'core:cancel': => @cancel()

    unless stayOpen
      @miniEditor.on 'blur', => @close()

    if placeholderText
      @miniEditor.getModel().setText placeholderText
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
