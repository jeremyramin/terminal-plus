module.exports =
  config: require './config-schema'
  core: null
  statusBar: null

  activate: ->
    @core = require './core'
    @statusBar = require './status-bar'

  deactivate: ->
    @core.destroy()
    @statusBar.destroy()
    @core = null
    @statusBar = null

  consumeStatusBar: (atomStatusBar) ->
    atom.config.observe 'terminal-plus.core.statusBar', (value) =>
      @statusBar.destroyContainer()

      switch value
        when "Full"
          @statusBar.setContainer atom.workspace.addBottomPanel {
            item: @statusBar
            priority: 100
          }
        when "Collapsed"
          @statusBar.setContainer atomStatusBar.addLeftTile {
            item: @statusBar
            priority: 100
          }
