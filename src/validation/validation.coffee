if typeof define isnt 'function'
	define = (require('amdefine') ) (module)

define [], () ->

	createValidationException = (message) ->
		{
			name: 'ValidationException',
			message: "ValidationException: #{message}"
		}

	isArray = Array.isArray || ( value ) -> return {} .toString.call( value ) is '[object Array]'

	valueHolder = (value) ->
		name = ""
		class Validators

			@withName = (valueName) ->
				name = valueName
				return @

			@exists = () ->
				if not value?
					throw createValidationException("Not defined: #{name if name?}")

			@isNumber = () =>
				@exists value
				if typeof value isnt 'number'
					throw createValidationException("Expected number. Was #{typeof value}: #{value}")

			@isArray = () =>
				@exists value
				if not isArray(value)
					throw createValidationException("Expected array. Was #{typeof value}: #{value}")

			@notNegative = () =>
				@isNumber value
				if value < 0
					throw createValidationException("Expected >0. Was: #{value}")

			@lessThan = (number) =>
				@isNumber value
				@isNumber number
				if value >= number
					throw createValidationException("Expected <#{number}. Was: #{value}")
	
	return {
		assert: valueHolder
	}