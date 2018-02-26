# that file was based in the tree-view file: movedialog.coffee
{Directory, File} = require 'atom'
path = require 'path'
fs = require 'fs'
dir_tree_wiew = atom.packages.resolvePackagePath('tree-view')
Dialog = require  dir_tree_wiew + '/lib/dialog'
{repoForPath} = require  dir_tree_wiew +  "/lib/helpers"

module.exports =
class MoveDialog extends Dialog
  constructor: (@img_filename, @assets_path, @assets_dir, @editor, @imgbuffer) ->
    prompt = 'Enter a name for the Image'

    super
      prompt: prompt
      initialPath: @img_filename
      select: true
      iconClass: 'icon-arrow-right'

  onConfirm: (filename) ->
    filename = filename.replace(/\s+$/, '') # Remove trailing whitespace
    thepath  = path.join(@assets_path, filename)
    return unless filename
    console.log(@assets_path)
    @createDir @assets_path, ()=>
      @writePng thepath, @imgbuffer, ()=>
        @insertUrl @assets_dir, filename, @editor

    @close()

  createDir: (dirPath, callback)->
    console.log(@assets_path)
    assetsDir = new Directory(dirPath)

    assetsDir.exists().then (existed) =>
      if not existed
        assetsDir.create().then (created) =>
          if created
            console.log 'Success Create dir'
            callback()
      else
        callback()

  writePng: (Path, buffer, callback)->
    fs = require('fs')
    fs.writeFile Path, buffer, 'binary',() =>
      console.log('finish clip image')
      callback()

  insertUrl: (assets_dir, filename, editor) ->
    relPath = assets_dir + '/' + filename
    selection = editor.getSelectedText()
    if selection.length > 0
      editor.insertText(filename)
    else
      editor.insertText("\\begin{figure}[!htb]\n\t\\centering\n\t\\includegraphics[width=0.95\\textwidth]{"+relPath+"}\n\t\\caption{}\n\t\\label{}\n\\end{figure}")
