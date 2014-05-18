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
		inlineName = -> if name isnt "" then "'#{name}' " else ""

		class Validators

			@withName = (valueName) ->
				name = valueName
				return @

			@exists = () ->
				if not value?
					throw createValidationException("Not defined: #{name}")

			@isNumber = () =>
				@exists value
				if typeof value isnt 'number'
					throw createValidationException("Expected #{inlineName()}to be number. Was #{typeof value}: #{value}")

			@isArray = () =>
				@exists value
				if not isArray(value)
					throw createValidationException("Expected #{inlineName()}to be array. Was #{typeof value}: #{value}")

			@notNegative = () =>
				@isNumber value
				if value < 0
					throw createValidationException("Expected #{inlineName()}to be >0. Was: #{value}")

			@lessThan = (number) =>
				@isNumber value
				@isNumber number
				if value >= number
					throw createValidationException("Expected #{inlineName()}to be <#{number}. Was: #{value}")

			@greaterThanOrEqualTo = (number) =>
				@isNumber value
				@isNumber number
				if value < number
					throw createValidationException("Expected #{inlineName()}to be >=#{number}. Was: #{value}")


	return {
		assert: valueHolder
	}
