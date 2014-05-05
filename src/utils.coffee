if typeof define isnt 'function'
	define = (require('amdefine') ) (module)

define [], () ->

	Utils =
		deepEquals: (obj1, obj2) ->
			[type_1, type_2] = [typeof obj1, typeof obj2]
			if type_1 isnt type_2
				return false
			if type_1 isnt 'object'
				return obj1 is obj2
			else
				if obj1 instanceof Array
					if obj2 instanceof Array
						if obj1.length is obj2.length
							return false for i in [0..obj1.length] when not Utils.deepEquals obj1[i], obj2[i]
						else
							return false
					else
						return false
				else
					# this is a hash-like thing
					keys = []
					(keys.push key unless key in keys) for own key, value of obj1
					(keys.push key unless key in keys) for own key, value of obj2
					return false for own key of keys when not Utils.deepEquals obj1[key], obj2[key]
			true

