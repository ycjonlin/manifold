'use strict'

Manuscript = require './manuscript'
Color = require './color'

abs = Math.abs
sign = Math.sign
step = (x)-> if x > 0 then 1 else 0

min = Math.min
max = Math.max

floor = Math.floor
ceil = Math.ceil
round = Math.round

sqrt = Math.sqrt
pow = Math.pow
exp = Math.exp
log = Math.log

cos = Math.cos
sin = Math.sin
tan = Math.tan

acos = Math.acos
asin = Math.asin
atan = Math.atan
atan2 = Math.atan2

cosh = (x)->
  exp_x = exp(x)
  (exp_x+1/exp_x)*0.5
sinh = (x)->
  exp_x = exp(x)
  (exp_x-1/exp_x)*0.5
tanh = (x)-> 
  exp_x = exp(x)
  (exp_x-1/exp_x)/(exp_x+1/exp_x)

acosh = (x)->
  log(x+sqrt(x*x-1))
asinh = (x)->
  log(x+sqrt(x*x+1))
atanh = (x)->
  log((1+x)/(1-x))*0.5

pi = Math.PI
tau = pi*2
ln2 = log(2)

norm = (x, y)-> sqrt(x*x+y*y)

class Point
  constructor: (@x, @y)->

class Rectangle
  constructor: (@x0, @y0, @x1, @y1)->

  diagnal: ->
    norm(@x1-@x0, @y1-@y0)

class Transform
  constructor: (@xx, @yx, @xy, @yy, @x, @y)->

  translate: (x, y)->
    new Transform(@xx, @yx, @xy, @yy, @x+x, @y+y)

  scale: (sx, sy, tx, ty)->
    new Transform(
      @xx*sx, @yx*sx, @xy*sy, @yy*sy, 
      (@x-tx)*sx+tx, (@y-ty)*sy+ty)

  map: (point)->
    new Point(
      +@xx*point.x+@xy*point.y+@x, 
      +@yx*point.x+@yy*point.y+@y)

  unmap: (point)->
    det = @xx*@yy-@xy*@yx
    x = point.x-@x
    y = point.y-@y
    new Point(
      (+@yy*x-@xy*y)/det, 
      (-@yx*x+@xx*y)/det)

  box: (rectangle)->
    p00 = @map new Point(rectangle.x0, rectangle.y0)
    p10 = @map new Point(rectangle.x1, rectangle.y0)
    p01 = @map new Point(rectangle.x0, rectangle.y1)
    p11 = @map new Point(rectangle.x1, rectangle.y1)

    x0 = min p00.x, p10.x, p01.x, p11.x
    x1 = max p00.x, p10.x, p01.x, p11.x

    y0 = min p00.y, p10.y, p01.y, p11.y
    y1 = max p00.y, p10.y, p01.y, p11.y

    new Rectangle(x0, y0, x1, y1)

  unbox: (rectangle)->
    p00 = @unmap new Point(rectangle.x0, rectangle.y0)
    p10 = @unmap new Point(rectangle.x1, rectangle.y0)
    p01 = @unmap new Point(rectangle.x0, rectangle.y1)
    p11 = @unmap new Point(rectangle.x1, rectangle.y1)

    x0 = min p00.x, p10.x, p01.x, p11.x
    x1 = max p00.x, p10.x, p01.x, p11.x

    y0 = min p00.y, p10.y, p01.y, p11.y
    y1 = max p00.y, p10.y, p01.y, p11.y

    new Rectangle(x0, y0, x1, y1)

  apply: (context)->
    context.transform @xx, @yx, @xy, @yy, @x, @y

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

class Fractal1D extends Layer

  constructor: (transforms, @expression)->
    super transforms, true

  _loop: (endpoint1, endpoint0, giantSteps, babySteps, expr, valid)->

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
      @transform().apply @context

      @_loop domain.x0, domain.x1, 1<<8, 1<<12, expr.bind(null, s), valid

      @context.restore()
      @context.lineWidth = 3
      @context.strokeStyle = @color
      @context.stroke()

class Fractal2D extends Layer

  constructor: (transforms, @expression, @distinguishable, @scheme)->
    super transforms, false

  _loop: (x0, x1, y0, y1, giantSteps, babySteps, expr, dist, scheme)->

    count = 0
    i0 = 0
    j0 = 0
    jump = ceil(babySteps/giantSteps)|0
    step = jump

    ox = x0
    oy = y0
    dx = (x1-x0)/babySteps
    dy = (y1-y0)/babySteps

    v0 = oy+dy*(j0)
    v1 = oy+dy*(j0+step)
    for _ in [1..1<<16]
      u0 = ox+dx*(i0)
      u1 = ox+dx*(i0+step)
      count += 1
      # expression
      w0 = expr(u0, v0)
      w2 = expr(u0, v1)
      w1 = expr(u1, v0)
      w3 = expr(u1, v1)
      # subdivision
      if step > 1 and dist(w0, w1) or dist(w0, w2) or dist(w1, w3) or dist(w2, w3)
        step >>= 1
        u1 = ox+dx*(i0+step)
        v1 = oy+dy*(j0+step)
        continue
      # render
      color = scheme((w0+w1+w2+w3)/4)
      @context.fillStyle = "rgb(#{color[0]},#{color[1]},#{color[2]})"
      @context.fillRect u0, v0, (u1-u0)*0.5, (v1-v0)*0.5
      # proceed
      i0 += step
      if (i0&step) == 0
        while (i0&step) == 0 and step < jump
          if (j0&step) == 0
            i0 -= step<<1
            j0 += step
            break
          j0 -= step
          step <<= 1
        if i0 == babySteps
          i0 = 0
          j0 += step
          if j0 == babySteps
            break
        v0 = oy+dy*(j0)
        v1 = oy+dy*(j0+step)
    console.log count

  _render: (domain)->
    
    expr = @expression
    dist = @distinguishable
    scheme = @scheme

    for s in [0..(1<<2)-1]
      @context.save()
      @transform().apply @context

      @_loop domain.x0, domain.x1, domain.y0, domain.y1, 1<<4, 1<<8, expr, dist, scheme

      @context.restore()

class Stack extends Element
  constructor: ->
    width = window.innerWidth
    height = window.innerHeight
    scale = norm(width, height)/8

    sign = (s)-> if s then 1 else -1
    factor = (s, c, x)-> sqrt(c)+sign(s)*sqrt(c-x)

    fractal = (x, y)-> min(1, x*x+y*y)
    metric = (z, w)-> abs(z-w)>0.05
    color = (z)-> [128, sqrt(z)*255|0,255]

    @anchor = null
    @transforms = [new Transform(
      scale, 0, 0, -scale, 
      width/2, height/2)]
    @layers = [
      new Fractal2D(@transforms, fractal, metric, color),
      new Grid(@transforms),
      new Axis(@transforms)
    ]

  render: ->
    for layer in @layers
      layer.render()

  $mouseDown: (event)->
    @anchor = new Point(event.clientX, event.clientY)
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
      event.clientX-@anchor.x, 
      event.clientY-@anchor.y)
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
