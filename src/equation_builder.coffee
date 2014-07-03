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
	 * @return {object}
	###
	createEquationBuilder: ({numOfNodes, numOfVSources} ) ->
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

		stampConductance = (conductance) -> (node1, node2) ->
			assert(conductance).withName('conductance').notNegative()
			stampNodalAdmittanceMatrix node1, node1, conductance
			stampNodalAdmittanceMatrix node2, node2, conductance
			stampNodalAdmittanceMatrix node1, node2, - conductance
			stampNodalAdmittanceMatrix node2, node1, - conductance

		stampResistance = (resistance) -> (node1, node2) ->
			if resistance is 0 then resistance = 1
			conductance = 1 / resistance
			stampConductance(conductance) node1, node2

		stampVoltageSource = (voltage) -> (fromNode, toNode) ->
			assert(numOfVoltageSourcesStamped).withName('number of voltage sources already stamped')
				.lessThan(numOfVSources)
			vIndex = numOfNodes + numOfVoltageSourcesStamped
			numOfVoltageSourcesStamped++
			stampNodalAdmittanceMatrix vIndex, fromNode, - 1
			stampNodalAdmittanceMatrix vIndex, toNode, 1
			stampNodalAdmittanceMatrix fromNode, vIndex, - 1
			stampNodalAdmittanceMatrix toNode, vIndex, 1
			stampInputVector vIndex, voltage
			vIndex

		stampCurrentSource = (current) -> (fromNode, toNode) ->
			stampInputVector fromNode, - current
			stampInputVector toNode, current

		stampControlledSouce = (gain) ->
			CC: (fromControlNode, toControlNode) ->
				vIndexControl = stampVoltageSource(0) fromControlNode, toControlNode
				CS: (fromSourceNode, toSourceNode) ->
					stampNodalAdmittanceMatrix fromSourceNode, vIndexControl, gain
					stampNodalAdmittanceMatrix toSourceNode, vIndexControl, - gain
				VS: (fromSourceNode, toSourceNode) ->
					vIndexSource = stampVoltageSource(0) fromSourceNode, toSourceNode
					stampNodalAdmittanceMatrix vIndexSource, vIndexControl, - gain
			VC: (fromControlNode, toControlNode) ->
				CS: (fromSourceNode, toSourceNode) ->
					stampNodalAdmittanceMatrix fromSourceNode, fromControlNode, gain
					stampNodalAdmittanceMatrix fromSourceNode, toControlNode, - gain
					stampNodalAdmittanceMatrix toSourceNode, fromControlNode, - gain
					stampNodalAdmittanceMatrix toSourceNode, toControlNode, gain
				VS: (fromSourceNode, toSourceNode) ->
					vIndexSource = stampVoltageSource(0) fromSourceNode, toSourceNode
					stampNodalAdmittanceMatrix vIndexSource, fromControlNode, - gain
					stampNodalAdmittanceMatrix vIndexSource, toControlNode, gain


		directional = (functionUsingNodes) ->
			from: (fromNode) ->
				to: (toNode) ->
					validateNodes(functionUsingNodes) fromNode, toNode

		nonDirectional = (functionUsingNodes) ->
			between: (fromNode, toNode) ->
				validateNodes(functionUsingNodes) fromNode, toNode

		validateNodes = (stampFunction) -> (fromNode, toNode) ->
			assert(fromNode).withName('fromNode').isBetween(0).and(numOfNodes - 1).inclusive()
			assert(toNode).withName('toNode').isBetween(0).and(numOfNodes - 1).inclusive()
			stampFunction fromNode, toNode

		stampGain = (gain) ->
			{CC, VC} = stampControlledSouce(gain)

			extendApi = (controllingType) ->
				(fromNode, toNode) ->
					{CS, VS} = controllingType(fromNode, toNode)
					controlling:
						a:
							currentSource: directional CS
							voltageSource: directional VS

			multiplying:
				a:
					current: directional extendApi CC
					voltage: directional extendApi VC

		###
		 * Stamp an element into the circuit equation.
		 * @param {number} value Value to stamp.
		 * @return {object} Choice of units to stamp.
		###
		stamp = (value) ->
			ohms: nonDirectional stampResistance(value)
			siemens: nonDirectional stampConductance(value)
			volts: directional stampVoltageSource(value)
			amps: directional stampCurrentSource(value)

		###
		 * Stamp a controlled source into the circuit equation.
		 * @param {number} gain
		 * @return {object}
		###
		stamp.a =
			gain:
				of: stampGain

		###
		@EXTERNAL
		###
		stamp: stamp
		getEquation: () ->
			nodalAdmittances: nodalAdmittances,
			inputs: inputs
