'use strict'

Manuscript = require './manuscript'
Color = require './color'
math = require 'mathjs'

createElement = (tag, classList, children)->
  element = document.createElement tag
  if classList
    for className in classList
      element.classList.add className
  if children
    for child in children
      element.appendChild child
  element

class Element
  dom: ->
    dom = @_dom()
    for key, value of @
      if key[0] == '$'
        if key[1] == '$'
          window.addEventListener key.toLowerCase()[2..], value.bind(@)
        else
          dom.addEventListener key.toLowerCase()[1..], value.bind(@)
    dom

class Layer extends Element
  @spectrum: Color.spectrumLight
  @serial: 3
  @nextColor: ->
    color = @spectrum[@serial]
    @serial = (@serial+1)%@spectrum.length
    "rgba(#{color[0]},#{color[1]},#{color[2]},0.75)"

  constructor: (transforms, isColored)->
    @canvas = createElement 'canvas', ['layer']
    @context = @canvas.getContext '2d'
    @transforms = transforms
    @color = if isColored then Layer.nextColor() else null

  render: ->
    transform = @transforms[@transforms.length-1]
    codomain = new Rectangle(0, 0, @canvas.width, @canvas.height)
    domain = transform.unbox codomain

    @context.clearRect 0, 0, @canvas.width, @canvas.height

    @_render domain

  transform: ()->
    @transforms[@transforms.length-1]

  $$resize: (event)->
    @canvas.width = window.innerWidth
    @canvas.height = window.innerHeight
    @render()

  _dom: ->
    @canvas

  _render: (self, transform)->

class Axis extends Layer
  constructor: (transforms)->
    super transforms, false

  _render: (domain)->
    scale = exp(floor(log(16/domain.diagnal())/ln2)*ln2)

    @context.save()
    @context.beginPath()
    @transform().apply @context

    @context.moveTo 0, domain.y0
    @context.lineTo 0, domain.y1

    @context.moveTo domain.x0, 0
    @context.lineTo domain.x1, 0

    @context.restore()
    @context.lineWidth = 1
    @context.strokeStyle = 'rgba(0,0,0,1)'
    @context.stroke()

class Grid extends Layer
  constructor: (transforms)->
    super transforms, false

  _render: (domain)->
    scale = exp(floor(log(16/domain.diagnal())/ln2)*ln2)

    @context.save()
    @context.beginPath()
    @transform().apply @context

    for i in [floor(domain.x0*scale)..ceil(domain.x1*scale)]
      if i == 0
        continue
      @context.moveTo i/scale, domain.y0
      @context.lineTo i/scale, domain.y1

    for i in [floor(domain.y0*scale)..ceil(domain.y1*scale)]
      if i == 0
        continue
      @context.moveTo domain.x0, i/scale
      @context.lineTo domain.x1, i/scale

    @context.restore()
    @context.lineWidth = 1
    @context.strokeStyle = 'rgba(0,0,0,0.125)'
    @context.stroke()

class Fractal extends Layer

  constructor: (transforms, @expression)->
    super transforms, true

  _loop: (endpoint0, endpoint1, giantSteps, babySteps, expr, valid)->

    du = (endpoint1-endpoint0)/babySteps
    ds = (endpoint1-endpoint0)/giantSteps*sqrt(2)
    dt = tau/64

    u0 = endpoint0
    v0 = expr(u0)
    b0 = false
    t0 = atan2(v0-expr(u0-du), du)

    count = 0
    lower = 0
    upper = babySteps
    jump = ceil(babySteps/giantSteps)|0
    step = jump

    while lower < upper
      count += 1
      u1 = u0+du*step
      v1 = expr(u1)
      b1 = valid(v1)
      t1 = atan2(v1-v0, u1-u0)
      if step > 1
        Du = u1-u0
        Dv = v1-v0
        if b0 != b1 or b1 and (Du*Du+Dv*Dv > ds*ds or abs(t1-t0) > dt)
          step >>= 1
          continue
      if b0 != b1 or b1
        if not b0
          @context.moveTo u0, v0
        @context.lineTo u1, v1
      u0 = u1
      v0 = v1
      b0 = b1
      t0 = t1
      lower += step
      while (lower&step) == 0 and step < jump
        step <<= 1

  _render: (domain)->
    
    expr = @expression
    valid = (v)-> v >= domain.y0 and v <= domain.y1

    for s in [0..(1<<2)-1]
      @context.save()
      @context.beginPath()
      self.transform().apply @context

      @_loop domain.x0, domain.x1, 1<<8, 1<<12, expr.bind(null, s), valid

      @context.restore()
      @context.lineWidth = 3
      @context.strokeStyle = @color
      @context.stroke()

class Stack extends Element
  constructor: ->
    width = window.innerWidth
    height = window.innerHeight
    scale = math.norm([width, height])/8

    sign = (s)-> if s then 1 else -1
    factor = (s, c, x)-> sqrt(c)+sign(s)*sqrt(c-x)

    @anchor = null
    @transforms = [
      math.matrix([
        [scale, 0, width/2],
        [0,-scale, height/2],
        [0, 0, 1]
      ])
    ]
    @layers = [
      new Grid(@transforms),
      new Axis(@transforms),
      new Fractal(@transforms, (s, x)-> 
        factor(  1, 4, x) *
        factor(s&1, 3, x) - 
        factor(  1, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  0, 4, x) *
        factor(s&1, 3, x) - 
        factor(  1, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  1, 4, x) *
        factor(s&1, 3, x) - 
        factor(  0, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  0, 4, x) *
        factor(s&1, 3, x) - 
        factor(  0, 2,-x) * 
        factor(s&2, 1,-x)),

      new Fractal(@transforms, (s, x)-> 
        factor(  1, 4, x) *
        factor(s&1, 3, x) +
        factor(  1, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  0, 4, x) *
        factor(s&1, 3, x) + 
        factor(  1, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  1, 4, x) *
        factor(s&1, 3, x) + 
        factor(  0, 2,-x) * 
        factor(s&2, 1,-x)),
      new Fractal(@transforms, (s, x)-> 
        factor(  0, 4, x) *
        factor(s&1, 3, x) + 
        factor(  0, 2,-x) * 
        factor(s&2, 1,-x)),
    ]

  render: ->
    for layer in @layers
      layer.render()

  $mouseDown: (event)->
    @anchor = math.matrix([event.clientX, event.clientY, 1])
    @transforms.push @transforms[-1..][0]
  $mouseUp: (event)->
    @anchor = null
  $mouseLeave: (event)->
    @anchor = null
  $mouseMove: (event)->
    if @anchor == null
      return
    array = @transforms
    array[array.length-1] = array[array.length-2].translate(
      event.clientX-@anchor.re, 
      event.clientY-@anchor.im)
    @render()

  $mouseWheel: (event)->
    value = if event.detail then event.detail*(-120) else event.wheelDelta
    value = exp(value/1024)
    array = @transforms
    array[array.length-1] = array[array.length-1].scale(
      value, value, event.clientX, event.clientY)
    @render()

  _dom: ->
    @container = createElement 'div', ['stack'], 
      layer.dom() for layer in @layers

# stack & layers
stack = new Stack()
content = document.getElementById 'content'
content.appendChild stack.dom()
window.dispatchEvent new Event('resize')
