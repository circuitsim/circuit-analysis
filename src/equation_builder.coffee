if typeof define isnt 'function'
	define = (require('amdefine') ) (module)

define ['./matrix', './validation/validation'], (Matrix, {assert} ) ->

	MIN_NUM_OF_NODES = 2

	createBlankEquation = (size) ->
		nodalAdmittances: Matrix.createBlankMatrix(size)
		inputs: Matrix.createBlankMatrix(size, 1)

	###
	 * Creates a blank equation which can be built up using 'stamps' for each element in the circuit.
	 * @param {int} numOfNodes
	 * @param {int} numOfVSources = 0
	 * @return {object	}
	###
	createEquationBuilder = ({numOfNodes, numOfVSources} ) ->
		numOfVSources ?= 0
		assert(numOfNodes).withName('numOfNodes').greaterThanOrEqualTo MIN_NUM_OF_NODES
		assert(numOfVSources).withName('numOfVSources').notNegative()

		# modified nodal analysis  (MNA)
		size = numOfNodes + numOfVSources - 1 # ignore ground node

		{nodalAdmittances, inputs} = createBlankEquation size
		numOfVoltageSourcesStamped = 0

		#	Stamp value x in [row][col], meaning that a voltage change of dv in node 'col'
		# will increase the current into node 'row' by x dv.
		# (Unless row or col is a voltage source node.)
		stampNodalAdmittanceMatrix = (row, col, x) ->
			if row isnt 0 and col isnt 0 # ignore ground node
				row--
				col--
				nodalAdmittances.set(row, col).plusEquals x

		# Stamp value x on the right side of 'row', representing an independent current source
		# flowing into node 'row'.
		stampInputVector = (row, x) ->
			if row isnt 0
				row--
				inputs.set(row).plusEquals x

		stampConductance = (node1, node2, conductance) ->
			assert(conductance).withName('conductance').notNegative()
			stampNodalAdmittanceMatrix node1, node1, conductance
			stampNodalAdmittanceMatrix node2, node2, conductance
			stampNodalAdmittanceMatrix node1, node2, - conductance
			stampNodalAdmittanceMatrix node2, node1, - conductance

		stampResistance = (node1, node2, resistance) ->
			if resistance is 0 then resistance = 1
			conductance = 1 / resistance
			stampConductance node1, node2, conductance

		stampVoltageSource = (fromNode, toNode, voltage) ->
			assert(numOfVoltageSourcesStamped).withName('number of voltage sources already stamped')
				.lessThan(numOfVSources)
			vIndex = numOfNodes + numOfVoltageSourcesStamped
			stampNodalAdmittanceMatrix vIndex, fromNode, 1
			stampNodalAdmittanceMatrix vIndex, toNode, - 1
			stampNodalAdmittanceMatrix fromNode, vIndex, 1
			stampNodalAdmittanceMatrix toNode, vIndex, - 1
			stampInputVector vIndex, voltage
			numOfVoltageSourcesStamped++

		stampCurrentSource = (fromNode, toNode, current) ->
			stampInputVector fromNode, - current
			stampInputVector toNode, current

		###
		@EXTERNAL
		###

		###
		 * Stamp an element into the circuit equation.
		 * @param {number} value Value to stamp.
		 * @return {object} Choice of units to stamp.
		###
		stamp: (value) ->
			doStamp = (fromNode, toNode, stampFunction) ->
				assert(fromNode).withName('fromNode').isBetween(0).and(numOfNodes - 1).inclusive()
				assert(toNode).withName('toNode').isBetween(0).and(numOfNodes - 1).inclusive()
				stampFunction fromNode, toNode, value

			stampUsing = (stampFunction) ->
				between: (fromNode, toNode) ->
					doStamp fromNode, toNode, stampFunction

			stampDirectionalUsing = (stampFunction) ->
				from: (fromNode) ->
					to: (toNode) ->
						doStamp fromNode, toNode, stampFunction

			ohms: stampUsing stampResistance
			siemens: stampUsing stampConductance
			volts: stampDirectionalUsing stampVoltageSource
			amps: stampDirectionalUsing stampCurrentSource

		getEquation: () ->
			nodalAdmittances: nodalAdmittances,
			inputs: inputs
