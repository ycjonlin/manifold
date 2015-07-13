bower = require 'gulp-bower'
browserify = require 'browserify'
browserSync = require 'browser-sync'
duration = require 'gulp-duration'
gulp = require 'gulp'
gutil = require 'gulp-util'
jade = require 'gulp-jade'
notifier = require 'node-notifier'
path = require 'path'
prefix = require 'gulp-autoprefixer'
replace = require 'gulp-replace'
rev = require 'gulp-rev'
rimraf = require 'rimraf'
sass = require 'gulp-ruby-sass'
source = require 'vinyl-source-stream'
sourcemaps = require 'gulp-sourcemaps'
streamify = require 'gulp-streamify'
uglify = require 'gulp-uglify'
watchify = require 'watchify'

production = process.env.NODE_ENV == 'production'

config = 
  destination: './public'

  bower:
    destination: './bower_components'

  scripts:
    source: './src/coffee/main.coffee'
    destination: './public/js/'
    transform: ['coffeeify']
    extensions: ['.coffee']
    filename: 'bundle.js'

  templates:
    source: './src/jade/*.jade'
    watch: './src/jade/*.jade'
    destination: './public/'
    revision: './public/**/*.html'

  styles:
    source: './src/sass/style.sass'
    path: [
      './src/sass'
      './bower_components/bootstrap-sass-official/assets/stylesheets'
      './bower_components/fontawesome/scss'
    ]
    watch: './src/sass/*.sass'
    destination: './public/css/'

  assets:
    source: './src/assets/**/*.*'
    watch: './src/assets/**/*.*'
    destination: './public/'

  revision:
    source: [
      './public/**/*.css'
      './public/**/*.js'
    ]
    base: path.join(__dirname, 'public')
    destination: './public/'

browserifyConfig = 
  entries: [config.scripts.source]
  transform: config.scripts.transform
  extensions: config.scripts.extensions
  debug: !production
  cache: {}
  packageCache: {}

handleError = (err) ->
  gutil.log err
  gutil.beep()
  notifier.notify
    title: 'Compile Error'
    message: err.message
  @emit 'end'

gulp.task 'bower', ->
  pipeline = bower()

  pipeline.pipe gulp.dest(config.bower.destination)

gulp.task 'scripts', ->
  pipeline = browserify browserifyConfig
    .bundle()
    .on 'error', handleError
    .pipe source(config.scripts.filename)

  if production
    pipeline = pipeline.pipe streamify(uglify())

  pipeline.pipe gulp.dest(config.scripts.destination)

gulp.task 'templates', ->
  pipeline = gulp.src(config.templates.source)
    .pipe jade(pretty: !production)
    .on 'error', handleError
    .pipe gulp.dest(config.templates.destination)
  
  if production
    return pipeline

  pipeline.pipe browserSync.reload(stream: true)

gulp.task 'styles', ->
  pipeline = sass(config.styles.source,
    style: if production then 'compressed' else 'expanded'
    loadPath: config.styles.path
  )
    .on 'error', handleError
    .pipe prefix('last 2 versions', 'Chrome 34', 'Firefox 28', 'iOS 7')

  if !production
    pipeline = pipeline.pipe sourcemaps.write('.')

  pipeline = pipeline.pipe gulp.dest(config.styles.destination)

  if production
    return pipeline

  pipeline.pipe browserSync.stream(match: '**/*.css')

gulp.task 'assets', ->
  gulp.src config.assets.source
    .pipe gulp.dest(config.assets.destination)

gulp.task 'server', ->
  browserSync
    open: false
    port: 9001
    server: baseDir: config.destination

gulp.task 'watch', ->
  gulp.watch config.templates.watch, ['templates']
  gulp.watch config.styles.watch, ['styles']
  gulp.watch config.assets.watch, ['assets']
  bundle = watchify(browserify(browserifyConfig))
  bundle.on('update', ->
    build = bundle.bundle()
      .on 'error', handleError
      .pipe source(config.scripts.filename)
    build
      .pipe gulp.dest(config.scripts.destination)
      .pipe duration('Rebundling browserify bundle')
      .pipe browserSync.reload(stream: true)
    return
  ).emit 'update'
  return

buildTasks = [
  'templates'
  'styles'
  'assets'
]

gulp.task 'revision', buildTasks.concat(['scripts']), ->
  gulp.src config.revision.source, base: config.revision.base
    .pipe rev()
    .pipe gulp.dest(config.revision.destination)
    .pipe rev.manifest()
    .pipe gulp.dest('./')

gulp.task 'replace-revision-references', [
  'revision'
  'templates'
], ->
  revisions = require './rev-manifest.json'
  pipeline = gulp.src config.templates.revision
  pipeline = Object.keys(revisions).reduce(((stream, key) ->
    stream.pipe replace(key, revisions[key])
  ), pipeline)
  pipeline.pipe gulp.dest(config.templates.destination)

gulp.task 'build', ->
  rimraf.sync config.destination
  gulp.start buildTasks.concat([
    'scripts'
    'revision'
    'replace-revision-references'
  ])
  return

gulp.task 'default', buildTasks.concat([
  'watch'
  'server'
])
