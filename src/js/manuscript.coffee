Color = require './color'

# mode
mode = CodeMirror.defineMode 'manuscript', (config, modeConfig) -> 
  spectrum = Color.spectrumLight
  spectrumIndex = 0
  nextColor = ->
    color = spectrum[spectrumIndex]
    spectrumIndex = (spectrumIndex+1)%spectrum.length
    "rgb(#{color[0]}, #{color[1]}, #{color[2]})"

  manuscriptOverlay = 
    startState: ->
      code: false
    copyState: (state) ->
      code: state.code
    token: (stream, state) ->
      state.combineTokens = null
      # color code
      if state.code
        state.code = false
        stream.skipToEnd()
        value = stream.current()
        return "color #{value}"
      # formula
      if stream.sol() and stream.match /^\$ /
        if stream.skipTo('#')
          state.code = true
        else
          stream.skipToEnd()
          state.code = false
        #console.log stream.current()
        return 'formula'
      # otherwise
      stream.next()
      null

  markdownConfig = 
    underscoresBreakWords: false
    taskLists: true
    fencedCodeBlocks: true
    strikethrough: true
  for attr in modeConfig
    markdownConfig[attr] = modeConfig[attr]
  markdownConfig.name = 'markdown'

  CodeMirror.overlayMode CodeMirror.getMode(config, markdownConfig), manuscriptOverlay

# editor
textarea = document.getElementById 'manuscript'
editor = CodeMirror.fromTextArea textarea,
  mode: 'manuscript'
  lineNumbers: false
  lineWrapping: true
  theme: 'manuscript'
  extraKeys: 
    Enter: 'newlineAndIndentContinueMarkdownList'
editor.on 'change', ->
  #console.log 'change'
