levelup = require 'levelup'
ttl = require 'level-ttl'
Promise = require 'bluebird'
_ = require 'lodash'

class Level
  # Convert `{a: x, b: y, c: z}` to `[{a: x}, {b: y}, {c: z}]`
  singularize= (obj) ->
    [] if _.isEmpty obj
    for k, v of obj
      do -> o = {}; o[k] = v; o

  # Convert `[{a: x}, {b: y}, {c: z}]` to `{a: x, b: y, c: z}`
  pluralize = (os) ->
    {} if _.isEmpty os
    reducer = (acc, obj, i) ->
      for k, v of obj
        acc[k] = v
      acc
    _.foldl os, reducer, {}

  constructor: (path, options, callback) ->
    @db = levelup path, options, (err, db) ->
      if err?
        callback err, null
      else
        # Scan for deletables for every 10 minutes
        defaultCheckFrequency = 1000 * 60 * 10
        db = ttl db, checkFrequency: options.checkFrequency or defaultCheckFrequency
        callback err, db

  # Promisify `LevelUp#close()`
  close: =>
    Promise.promisify(@db.close).call @db

  # Promisify `LevelUp#get()`
  get: (key) =>
    Promise.promisify(@db.get).apply @db, arguments

  gets: (keys) ->
    promisses = _.map keys, (k) =>
      @get k
        .then (v) ->
          o = {}; o[k] = v; o
    Promise.all promisses
      .then (value) -> pluralize value

  # Promisify `LevelUp#put()`
  put: (key, value, ttl) =>
    options = if ttl? then ttl: ttl else {}
    Promise.promisify(@db.put).call @db, key, value, options
      .then ->
        result = {}
        result[key] = value
        result
      .catch (e) ->
        throw e

  # Accepts [{key1: value1}, {key2: value2}, ..., {keyn, valuen}], ttl
  # or [{key1: value1, key2: value2}, ..., {keyn, valuen}], ttl
  # objects - objects to be put
  # ttl - TTL in millisecs
  puts: (objects, ttl) =>
    ops = _.chain objects
      .filter (obj) -> not _.isEmpty obj
      .map (obj) ->
        for k, v of obj
          type: 'put', key: k, value: v
      .flatten()
      .value()
    options = if ttl? then ttl: ttl else {}
    Promise.promisify(@db.batch).call @db, ops, options
      .then ->
        true
      .catch (e) ->
        throw e

  # Promisify `LevelUp#del()`
  del: (key, options) =>
    Promise.promisify(@db.del).call @db, key, options

  # Just a transfer method to `LevelUp#isOpen()`
  isOpen: =>
    @db.isOpen()

  # Just a transfer method to `LevelUp#isClosed()`
  isClosed: =>
    @db.isClosed()

exports.Level = module.exports.Level = Level
