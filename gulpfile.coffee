gulp = require 'gulp'
mocha = require 'gulp-mocha'


gulp.task 'test', ->
  process.env.NODE_ENV = 'test'
  gulp.src './test/**/*.spec.coffee'
    .pipe mocha
      reporter: 'spec'
      compilers: 'coffee:coffee-script/register'
    .on 'error', (e) ->
      throw e


gulp.task('default', ['test'])
