Matrix = require '../src/matrix'
{createEquationBuilder} = require '../src/equation_builder'

blankThreeNodeEquation =
	nodalAdmittances: new Matrix [[0, 0]
																[0, 0]]
	inputs: new Matrix [[0]
											[0]]

describe 'Equation Builder:', ->
	it 'should initialise to a blank equation', ->
		{getEquation} = createEquationBuilder { numOfNodes: 3}
		expect(getEquation() ).to.eql blankThreeNodeEquation

	it 'should accept number of voltage sources as an optional parameter', ->
		{getEquation} = createEquationBuilder {numOfNodes: 2, numOfVSources: 1}
		expect(getEquation() ).to.eql blankThreeNodeEquation

	it 'should throw an exception if given a number of nodes < 2', ->
		expect( -> createEquationBuilder {numOfNodes: 1} ).to.throw /.*numOfNodes.*/

	it 'should throw an exception if given a number of voltage sources < 0', ->
		expect( -> createEquationBuilder {numOfNodes: 2, numOfVSources: - 1} ).to.throw /.*numOfVSources.*/

	describe 'Stamping', ->

		it 'should not accept out of bounds nodes', ->
			{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
			between = stamp(10).ohms.between
			expect( -> between(0, 3) ).to.throw 'ValidationException'
			expect( -> between( - 1, 2) ).to.throw 'ValidationException'

		describe 'stamping a resistance', ->
			it 'should stamp a resistance into the nodal admittance matrix', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(5).ohms.between(1, 2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[1/5, - 1/5]
																							 										[ - 1/5, 1/5]]
				expect(getEquation().inputs).to.eql blankThreeNodeEquation.inputs

			it 'should be additive', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(5).ohms.between(0, 2)
				stamp(5).ohms.between(1, 2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[1/5, - 1/5]
																							 										[ - 1/5, 2/5]]

			it 'should stamp 1 ohm instead of a zero resistance', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(0).ohms.between(1, 2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[1, - 1]
																																	[ - 1, 1]]

			it 'should not stamp a negative resistance', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				expect( -> stamp( - 1).ohms.between(1, 2) ).to.throw 'ValidationException'

		describe 'stamping a conductance', ->
			it 'should stamp a conductance', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(5).siemens.between(1, 2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[5, - 5]
																							 										[ - 5, 5]]
				expect(getEquation().inputs).to.eql blankThreeNodeEquation.inputs

			it 'should be additive', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(5).siemens.between(0, 2)
				stamp(5).siemens.between(1, 2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[5, - 5]
																							 										[ - 5, 10]]

			it 'should not stamp a negative conductance', ->
				{stamp} = createEquationBuilder { numOfNodes: 2}
				expect(-> stamp( - 1).siemens.between(0, 1) ).to.throw 'ValidationException'

		describe 'stamping a voltage source', ->
			it 'should stamp a voltage into the input vector', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
				stamp(5).volts.from(1).to(2)
				expect(getEquation().inputs).to.eql new Matrix [[0]
																							 					[0]
																							 					[5]]

			it 'should stamp into the augmented part of the nodal admittance matrix', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
				stamp(5).volts.from(1).to(2)
				expect(getEquation().nodalAdmittances).to.eql new Matrix [[0, 0, - 1]
																					 												[0, 0, 1]
																					 												[ - 1, 1, 0]]

			it 'should not stamp more than the specified number of voltage sources', ->
				{stamp} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
				stamp(5).volts.from(0).to(1)
				expect( -> stamp(5).volts.from(0).to(1) ).to.throw 'ValidationException'

		describe 'stamping a current source', ->
			it 'should stamp a current source', ->
				{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
				stamp(5).amps.from(1).to(2)
				expect(getEquation().inputs).to.eql new Matrix [[ - 5]
																							 					[5]]
				expect(getEquation().nodalAdmittances).to.eql blankThreeNodeEquation.nodalAdmittances

		describe 'controlled sources', ->
			describe 'stamping a current controlled current source', ->
				it 'should stamp a CCCS', ->
					{stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 1}

					stamp.a.gain.of(10).multiplying.a.current.from(1).to(2)
						.controlling.a.currentSource.from(2).to(3)

					expect(getEquation().nodalAdmittances).to.eql new Matrix [[ 0, 0, 0, - 1 ]
																																		[ 0, 0, 0, 11 ]
																																		[ 0, 0, 0, - 10 ]
																																		[ - 1, 1, 0, 0 ]]

			describe 'stamping a current controlled voltage source', ->
				it 'should stamp a CCVS', ->
					{stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 2}

					stamp.a.gain.of(10).multiplying.a.current.from(1).to(2)
						.controlling.a.voltageSource.from(2).to(3)

						expect(getEquation().nodalAdmittances).to.eql new Matrix [[ 0, 0, 0, - 1, 0 ]
																																			[ 0, 0, 0, 1, - 1 ]
																																			[ 0, 0, 0, 0, 1 ]
																																			[ - 1, 1, 0, 0, 0 ]
																																			[ 0, - 1, 1, - 10, 0 ]]


			describe 'stamping a voltage controlled current source', ->
				it 'should stamp a VCCS', ->
					{stamp, getEquation} = createEquationBuilder { numOfNodes: 3}

					stamp.a.gain.of(10).multiplying.a.voltage.from(0).to(1)
						.controlling.a.currentSource.from(1).to(2)

					expect(getEquation().nodalAdmittances).to.eql new Matrix [[ - 10, 0]
																																		[10, 0]]

			describe 'stamping a voltage controlled voltage source', ->
				it 'should stamp a VCVS', ->
					{stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 1}

					stamp.a.gain.of(10).multiplying.a.voltage.from(1).to(2)
						.controlling.a.voltageSource.from(2).to(3)

					expect(getEquation().nodalAdmittances).to.eql new Matrix [[ 0, 0, 0, 0 ]
																																		[ 0, 0, 0, - 1 ]
																																		[ 0, 0, 0, 1 ]
																																		[ -10, 9, 1, 0 ]]
