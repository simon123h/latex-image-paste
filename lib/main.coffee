
{CompositeDisposable,File,Directory} = require 'atom'

module.exports =

  config:
    imgPath:
      title: 'Image directory name'
      description: 'The name of the directory that is created, when an image is pasted'
      type: 'string'
      default: 'img'

	activate: (state) ->
		atom.commands.onWillDispatch (e)  =>
			if e.type is "core:paste"

				editor = atom.workspace.getActiveTextEditor()
				return unless editor
				grammar = editor.getGrammar()
				return unless grammar
				return unless grammar.scopeName is 'text.tex.latex'


				clipboard = require 'clipboard'
				img = clipboard.readImage()
        imgPath = atom.config.get('latex-image-paste.imgPath')

				return if img.isEmpty()

				e.stopImmediatePropagation()

				imgbuffer = img.toPng()

				thefile = new File(editor.getPath())
				assetsDirPath = thefile.getParent().getPath() + imgPath


				crypto = require "crypto"
				md5 = crypto.createHash 'md5'
				md5.update(imgbuffer)

				filename = "#{thefile.getBaseName().replace(/\.\w+$/, '').replace(/\s+/g,'')}-#{md5.digest('hex').slice(0,5)}.png"

				@createDirectory assetsDirPath, ()=>
					@writePng assetsDirPath+'/', filename, imgbuffer, ()=>
						@insertUrl imgPath + "/#{filename}",editor

				return false

	createDirectory: (dirPath, callback)->
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


	serialize: ->
