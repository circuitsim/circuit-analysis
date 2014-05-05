# Cakefile
 
{exec} = require "child_process"
 
REPORTER = "spec"
 
task "test", "run tests", ->
  exec "NODE_ENV=test 
    ./node_modules/.bin/mocha 
    --compilers coffee:coffee-script/register
    --reporter #{REPORTER}
    --require coffee-script
    --require test/test_helper.coffee
    --colors
  ", (err, output) ->
    console.log output
    throw err if err




