if typeof define isnt 'function'
	define = (require('amdefine') ) (module)

define [], () ->

	createValidationException = (message) ->
		{
			name: 'ValidationException',
			message: "ValidationException: #{message}"
		}

	isArray = Array.isArray or ( value ) -> return {} .toString.call( value ) is '[object Array]'

	assert: (value) =>
		name = ''
		inlineName = -> if name isnt '' then "'#{name}' " else ''

		class Validators

			@withName = (valueName) =>
				name = valueName
				return @

			@exists = () ->
				if not value?
					throw createValidationException("Not defined: #{name}")

			@isNumber = () =>
				@exists value
				if typeof value isnt 'number'
					throw createValidationException("Expected #{inlineName()}to be number.
						Was #{typeof value}: #{value}")

			@isArray = () =>
				@exists value
				if not isArray(value)
					throw createValidationException("Expected #{inlineName()}to be array.
						Was #{typeof value}: #{value}")

			@notNegative = () =>
				@isNumber value
				if value < 0
					throw createValidationException("Expected #{inlineName()}to be >0.
						Was: #{value}")

			@lessThan = (number) =>
				@isNumber value
				@isNumber number
				if value >= number
					throw createValidationException("Expected #{inlineName()}to be <#{number}.
						Was: #{value}")

			@greaterThan = (number) =>
				@isNumber value
				@isNumber number
				if value <= number
					throw createValidationException("Expected #{inlineName()}to be >#{number}.
						Was: #{value}")

			@lessThanOrEqualTo = (number) =>
				@isNumber value
				@isNumber number
				if value > number
					throw createValidationException("Expected #{inlineName()}to be <=#{number}.
							Was: #{value}")

			@greaterThanOrEqualTo = (number) =>
				@isNumber value
				@isNumber number
				if value < number
					throw createValidationException("Expected #{inlineName()}to be >=#{number}.
							Was: #{value}")

			@isBetween = (lower) =>
				and: (upper) =>
					inclusive: =>
						@greaterThanOrEqualTo lower
						@lessThanOrEqualTo upper
					exclusive: =>
						@greaterThan lower
						@lessThan upper
