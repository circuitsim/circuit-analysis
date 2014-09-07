# Cakefile

{spawn} = require 'child_process'
rimraf = require 'rimraf'

launch = (cmd, options = [], callback) ->
  app = spawn cmd, options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) ->
    callback?() if status is 0

build = ({watch, callback} = {}) ->
  rimraf './lib', ->
    watch ?= false
    options = [
      '--compile'
      '--bare' # Compile the JavaScript without the top-level function safety wrapper
      '--output', 'lib'
      'src'
      ]
    options.unshift '-w' if watch
    launch 'coffee', options, callback

doc = ->
  options = [
    './lib/'
    '-d', './docs'
  ]
  launch './node_modules/.bin/jsdoc', options

mocha = (options, callback) ->
  options ?= [
    "--compilers", "coffee:coffee-script/register"
    "--reporter", "spec"
    "--require", "coffee-script"
    "--require", "test/test_helper.coffee"
    "--colors"
    ]

  launch './node_modules/.bin/mocha', options, callback

task 'build', 'compile source', -> build()

task 'doc', 'create documentation', -> doc()

task 'watch', 'compile and watch', -> build watch: true

task 'test', 'run tests', -> build callback: -> mocha()
