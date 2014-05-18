{assert, validate} = require("../src/validation/validation")

describe 'Validation', ->

	describe 'assert', ->

		describe 'exists', ->
			it 'should give a useful error message', ->
				expect(-> assert(null).withName('myVarName').exists()).to.throw("ValidationException: Not defined: myVarName")

		describe 'notNegative', ->
			it 'should not throw an exception if positive', ->
				expect(-> assert(1).notNegative() ).to.not.throw()
			it 'should not throw an exception if zero', ->
				expect(-> assert(0).notNegative() ).to.not.throw()
			it 'should throw an exeption if <0', ->
				expect(-> assert(-1).notNegative()).to.throw("ValidationException: Expected to be >0. Was: -1")

		describe 'isNumber', ->
			it 'should not throw an exception if given a number', ->
				expect(-> assert(5).isNumber()).to.not.throw()
			it 'should throw an exception if given a string', ->
				expect(-> assert("5").isNumber()).to.throw("ValidationException: Expected to be number. Was string: 5")
			it 'should give a more explicit message when given a name', ->
				expect(-> assert("5").withName("name").isNumber()).to.throw("ValidationException: Expected 'name' to be number. Was string: 5")

		describe 'isArray', -> 
			it 'should not throw an exception if given an array', ->
				expect(-> assert([]).isArray()).to.not.throw()
			it 'should throw an exception if given an object', ->
				expect(-> assert({}).isArray()).to.throw("ValidationException: Expected to be array. Was object: [object Object]")

		describe 'lessThan', ->
			it 'should not throw an exception when <', ->
				expect(-> assert(1).lessThan(2)).to.not.throw()
			it 'should throw an exception when equal', ->
				expect(-> assert(1).lessThan(1)).to.throw("Expected to be <1. Was: 1")
			it 'should throw an exception when >', ->
				expect(-> assert(2).lessThan(1)).to.throw("Expected to be <1. Was: 2")

		describe 'greaterThanOrEqualTo', ->
			it 'should not throw an exception when >', ->
				expect(-> assert(2).greaterThanOrEqualTo(1)).to.not.throw
			it 'should not throw an exception when equal', ->
				expect(-> assert(1).greaterThanOrEqualTo(1)).to.not.throw
			it 'should throw an exception when <', ->
				expect(-> assert(1).greaterThanOrEqualTo(2)).to.throw("Expected to be >=2. Was: 1")

