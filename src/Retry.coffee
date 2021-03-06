
emptyFunction = require "emptyFunction"
assertType = require "assertType"
Random = require "random"
Timer = require "timer"
Null = require "Null"
Type = require "Type"

type = Type "Retry"

type.defineArgs ->

  types:
    fuzz: Number.or Null
    baseTimeout: Number
    exponent: Number
    maxTimeout: Number
    minTimeout: Number
    minCount: Number
    canRetry: Function

  defaults:
    fuzz: 0.5
    baseTimeout: 1000 # ms
    exponent: 2.2 # exponential backoff
    maxTimeout: 5 * 6e4 # 5 minutes
    minTimeout: 10
    minCount: 2
    canRetry: emptyFunction.thatReturnsTrue

type.defineValues (options) -> options

type.defineGetters

  retries: -> @_retries

  isRetrying: -> @_retryTimer isnt null

type.defineFunction (callback) ->
  return if @_retryTimer
  assertType callback, Function.Kind
  @_callback = callback
  timeout = @_computeTimeout @_retries
  @_retryTimer = Timer timeout, @_retry
  return

type.defineMethods

  reset: ->

    if @_retryTimer
      @_retryTimer.stop()
      @_retryTimer = null

    @_retries = 0
    @_callback = null
    return

#
# Internal
#

type.defineValues

  _retries: 0

  _retryTimer: null

  _callback: null

type.defineBoundMethods

  _retry: ->
    return unless @canRetry()
    callback = @_callback
    @_callback = null
    @_retryTimer = null
    @_retries += 1
    callback()
    return

type.defineMethods

  _computeTimeout: (count) ->
    return @minTimeout if count < @minCount
    timeout = @baseTimeout * Math.pow @exponent, count - @minCount
    @_applyFuzz Math.min timeout, @maxTimeout

  _applyFuzz: (timeout) ->
    return timeout if @fuzz is null
    fuzz = @fuzz * Random.fraction()
    fuzz += 1 - @fuzz / 2
    timeout * fuzz

module.exports = type.build()
