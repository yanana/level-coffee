chai = require 'chai'
chai.should()
chaiAsPromised = require 'chai-as-promised'
chai.use chaiAsPromised
expect = chai.expect
_ = require 'lodash'
sinon = require 'sinon'
{Level} = require '..'
memdown = require 'memdown'

describe 'A LevelDB interface', ->
  level = null
  beforeEach (done) ->
    level = new Level '/', db: memdown, () ->
      level.db.batch [
        {type: 'put', key: 'a', value: '1'}
        {type: 'put', key: 'b', value: '2'}
        {type: 'put', key: 'c', value: '3'}
        {type: 'put', key: 'd', value: '4'}
        {type: 'put', key: 'foo', value: 'bar'}
      ], (err) ->
        console.log err if err?
        done()

  describe '#get()', ->
    it 'should return a promissed value', ->
      level.get('a').should.eventually.equal '1'
    it "should reject when the value
    which coresponds to the given key does not exist", ->
      level.get('あ').should.be.rejected
      level.get('い')
        .catch (e) ->
          e.type.should.equal 'NotFoundError'

  describe '#put()', ->
    it 'should put a value and return a promise', ->
      level.put 'x', 'foo'
        .then ->
          level.get 'x'
            .should.eventually.equal 'foo'
    it 'should keep a previous value when put operation failed', ->
      stub = sinon.stub level.db, 'put', (k, v, opts) ->
        throw new Error('Wow!!')
      # stub.throws('TypeError')
      level.get 'foo'
        .should.eventually.equal 'bar'
      level.put 'foo', 'BAR', 10000
        .should.be.rejected
      level.get 'foo'
        .should.eventually.equal 'bar'
    it 'should reject empty value', ->
      level.put('X', '').should.be.rejected
    it 'should reject null value', ->
      level.put('X', null).should.be.rejected
    it 'should store JavaScript object as just a strings', ->
      o = x: 1, y: '2'
      level.put 'Obj', JSON.stringify o
        .then ->
          level.get 'Obj'
        .then (obj) ->
          obj.should.be.a 'string'
          JSON.parse(obj).should.deep.equal o

  describe '#puts()', ->
    it 'should put values and return a promise', ->
      level.puts [{a: 100, b: 200}, {c: 300}, {d: 400}]
        .then ->
          level.get 'a'
            .should.eventually.equal '100'
        .then ->
          level.get 'b'
            .should.eventually.equal '200'
        .then ->
          level.get 'c'
            .should.eventually.equal '300'
        .then ->
          level.get 'd'
            .should.eventually.equal '400'

  describe '#gets()', ->
    it 'should return a promise that would return values', ->
      level.gets ['a', 'b', 'c']
        .should.eventually.deep.equal {a: '1', b: '2', c: '3'}

  describe '#del()', ->
    it 'should delete an existent key', ->
      level.get 'b'
        .should.be.eventually.equal '2'
      level.del 'b'
        .then ->
          level.get 'a'
            .should.be.eventually.equal '1'
        .then ->
          level.get 'b'
            .should.be.rejected
    it 'should does not result to an error if specified key is not occupied', ->
      level.del 'hoge'
        .catch ->
          throw new Error()

