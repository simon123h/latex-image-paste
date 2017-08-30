{CompositeDisposable, Directory, File} = require 'atom'
fs = require 'fs'
path = require 'path'
crypto = require "crypto"

defaultImageDir = "img"

module.exports = MarkdownImageAssistant =
  subscriptions: null
  config:
    imageDir:
      title: "Image directory"
      description: "Local directory to copy images into; created if not found."
      type: 'string'
      default: defaultImageDir
    prependTargetFileName:
      title: "Prepend the target file name"
      description: "Whether to prepend the target file name when copying over the image. Overrides the \"Preserve Original Name\" setting."
      type: 'boolean'
      default: true

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register handler for copy and paste events
    @subscriptions.add atom.commands.onWillDispatch (e) =>
      if event? and event.type == 'core:paste'
        editor = atom.workspace.getActiveTextEditor()
        return unless editor
          grammar = editor.getGrammar()
          return unless grammar
          return unless grammar.scopeName is 'text.tex.latex'
        @handle_cp(e)



  # triggered in response to a copy pasted image
  handle_cp: (e) ->
    clipboard = require 'clipboard'
    img = clipboard.readImage()
    return if img.isEmpty()
    editor = atom.workspace.getActiveTextEditor()
    e.stopImmediatePropagation()
    imgbuffer = img.toPng()
    @process_file(editor, imgbuffer, ".png")

  # write a given buffer to the local "assets/" directory
  process_file: (editor, imgbuffer, extname) ->
    target_file = editor.getPath()
    assets_dir = path.basename(atom.config.get('latex-image-paste.imageDir'))
    assets_path = path.join(target_file, "..", assets_dir)


    md5 = crypto.createHash 'md5'
    md5.update(imgbuffer)

    if !atom.config.get('latex-image-paste.prependTargetFileName')
      img_filename = "#{md5.digest('hex').slice(0,8)}#{extname}"
    else
      img_filename = "#{path.parse(target_file).name}-#{md5.digest('hex').slice(0,8)}#{extname}"

    console.log img_filename

    @createDir assets_path, ()=>
      @writePng assets_path+'/', img_filename, imgbuffer, ()=>
        @insertUrl assets_dir + "/#{img_filename}",editor

    return false


  createDir: (dirPath, callback)->
    assetsDir = new Directory(dirPath)

    assetsDir.exists().then (existed) =>
      if not existed
        assetsDir.create().then (created) =>
          if created
            console.log 'Success Create dir'
            callback()
      else
        callback()

  writePng: (assetsDir, filename, buffer, callback)->
    fs = require('fs')
    fs.writeFile assetsDir+filename, buffer, 'binary',() =>
      console.log('finish clip image')
      callback()

  insertUrl: (url,editor) ->
    editor.insertText("\\begin{figure}[!htb]\n\t\\centering\n\t\\includegraphics[width=0.95\\textwidth]{"+url+"}\n\t\\caption{}\n\t\\label{}\n\\end{figure}")

  deactivate: ->
    @subscriptions.dispose()
