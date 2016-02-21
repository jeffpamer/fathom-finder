module.exports =
  config:
    ignoredNames:
      type: 'array'
      default: []
      description: 'List of string glob patterns. Files and directories matching these patterns will be ignored. This list is merged with the list defined by the core `Ignored Names` config setting. Example: `.git, ._*, Thumbs.db`.'
    searchAllPanes:
      type: 'boolean'
      default: true
      description: 'Search all panes when opening files. If disabled, only the active pane is searched. Holding `shift` inverts this setting.'
    preserveLastSearch:
      type: 'boolean'
      default: false
      description: 'Remember the typed query when closing the fuzzy finder and use that as the starting query next time the fuzzy finder is opened.'

  activate: (state) ->
    @active = true

    atom.commands.add 'atom-workspace',
      'fathom-finder:toggle-file-finder': =>
        @createProjectView().toggle()

    process.nextTick => @startLoadPathsTask()

    for editor in atom.workspace.getTextEditors()
      editor.lastOpened = state[editor.getPath()]

    atom.workspace.observePanes (pane) ->
      pane.observeActiveItem (item) -> item?.lastOpened = Date.now()

  deactivate: ->
    if @projectView?
      @projectView.destroy()
      @projectView = null
    @projectPaths = null
    @stopLoadPathsTask()
    @active = false

  serialize: ->
    paths = {}
    for editor in atom.workspace.getTextEditors()
      path = editor.getPath()
      paths[path] = editor.lastOpened if path?
    paths

  createProjectView: ->
    @stopLoadPathsTask()

    unless @projectView?
      ProjectView  = require './project-view'
      @projectView = new ProjectView(@projectPaths)
      @projectPaths = null
    @projectView

  startLoadPathsTask: ->
    @stopLoadPathsTask()

    return unless @active
    return if atom.project.getPaths().length is 0

    PathLoader = require './path-loader'
    @loadPathsTask = PathLoader.startTask (@projectPaths) =>
    @projectPathsSubscription = atom.project.onDidChangePaths =>
      @projectPaths = null
      @stopLoadPathsTask()

  stopLoadPathsTask: ->
    @projectPathsSubscription?.dispose()
    @projectPathsSubscription = null
    @loadPathsTask?.terminate()
    @loadPathsTask = null
