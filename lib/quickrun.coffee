{BufferedProcess} = require "atom"
util = require "util"
temp = require("temp").track()
extend = require "node.extend"

module.exports =
  specs:
    "Ruby":
      cmd: "ruby"
      args: ["-e", "%s"]
    "Perl":
      cmd: "perl"
      args: ["-e", "%s"]
    "Python":
      cmd: "python"
      args: ["-c", "%s"]

  editor: null

  activate: (state) ->
    atom.workspaceView.command "quickrun:execute", => @execute()
    extend @specs, (atom.config.get("quickrun.specs") or {})

  execute: ->
    editor = atom.workspace.getActiveEditor()
    grammar = editor.getGrammar()
    spec = @specs[grammar.name]
    return unless spec?
    command = spec.cmd
    args = spec.args
    options = spec.options
    code = editor.getBuffer().getText()
    args = (util.format arg, code for arg in args)
    @executeCore command, args, options

  executeCore: (command, args, options = {}) ->
    options = extend
      env: process.env
      , options
    stdout = (output) =>
      @handleOutput(output)
    stderr = (output) =>
      @hundleOutput(output)
    new BufferedProcess({command, args, options, stdout, stderr})

  handleOutput: (output) ->
    if @editor?
      @showResult(output)
    else
      temp.open "quickrun", (_, info) =>
        atom.workspace
          .open(info.path, split: 'right', activatePane: true)
          .done (editor) =>
            @editor = editor
            atom.subscribe @editor.getBuffer(), "destroyed", =>
              @editor = null
            @showResult(output)

  showResult: (output) ->
    buffer = @editor.getBuffer()
    buffer.setText(output)
    buffer.save()
