# Load all required libraries.
gulp            = require 'gulp'
svgo            = require 'gulp-svgo'
iconfont        = require 'gulp-iconfont'
Table           = require 'cli-table2'
fontmin         = require 'gulp-fontmin'
cheerio         = require 'gulp-cheerio'
pug             = require 'gulp-pug'
svg2png         = require 'gulp-svg2png'

paths = 
  components: 'build/components'
  sass: 'build/sass/*.sass'
  css: 'web/themes/formaphile/css/'
  res: 'web/themes/formaphile/res/'
  examples: 'web/themes/formaphile/examples/'
  icons: 'build/icons/'
  js: 'web/themes/formaphile/js/'

resizeForPng = ($, file) ->
  $svg = $ 'svg'
  $svg.attr 'height', 500
  $svg.attr 'width', 500
  $svg.attr 'preserveAspectRatio', 'xMidYMid'

cleanUpFigmaSVG = ($, file) ->
  
  # replace once reference
  $uses = $ 'use'
  $uses.each ->
    $use = $ @

    transform = $use.attr 'transform'
    selector = $use.attr 'xlink:href'
    $target = $ selector
    $target.attr 'transform', transform

    $use.replaceWith $target

  $ '[figma\\:type]'
    .removeAttr 'figma:type'

  $ '[fill="#FFFFFF"]'
    .remove()

gulp.task 'build', ->

  glyphList = new Array

  options = 
    fontName: 'DIn pIqaD'
    prependUnicode: true
    ascent: 588.235
    descent: 235.294
    fontHeight: 1000

  svgoPlugins = [
    transformsWithOnePath: yes
    removeEditorsNSData: yes
    removeDesc: yes
    removeTitle: yes
    collapseGroups: yes
  ]
  
  gulp
    .src 'svg/*.svg'
    .pipe cheerio cleanUpFigmaSVG
    .pipe svgo plugins: svgoPlugins
    .pipe gulp.dest 'processed-svg'
    .pipe iconfont options
    .on 'glyphs', (glyphs, options) ->
      console.log 'Create font "' + options.fontName + '"'
      table = new Table('head': [
        'NAME'
        'UNICODE'
      ])
      for index of glyphs
        table.push [
          glyphs[index].name
          glyphs[index].unicode[0]
        ]
        glyphList.push [
          glyphs[index].name
          glyphs[index].unicode[0]
        ]
      console.log table.toString()

      pugOpts = 
        locals:
          glyphs: glyphList 

      gulp
        .src 'demo.pug'
        .pipe pug pugOpts
        .pipe gulp.dest 'demo'

      return
    .pipe gulp.dest 'dist'

  return gulp
    .src 'svg/*.svg'
    .pipe cheerio resizeForPng
    .pipe svg2png()
    .pipe gulp.dest './png'
  


gulp.task 'watch', ['build'], ->
  gulp.watch 'svg/*.svg', ['build']
  gulp.watch 'demo.pug', ['build']

# Default task call every tasks created so far.
gulp.task 'default', ['watch']