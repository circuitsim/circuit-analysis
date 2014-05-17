if typeof define isnt 'function'
	define = (require('amdefine') ) (module)

define ['./utils', './validation/validation'], (utils, {assert} ) =>

	# @param ([[number]]) m
	# @return ([[number]])
	copy = (m) ->
		newMatrix = []
		for row, rowIndex in m
			newMatrix.push([])
			for c in row
				newMatrix[rowIndex].push(c)
		return newMatrix

	# Represents a Matrix
	class Matrix

		###
		Solve the matrix equation Ax = b for x.
		@param (Matrix) A NxN
		@param (Matrix) b Nx1
		@return (Matrix) x Nx1
		###
		@solve = (A, b) ->
			# TODO assert sizes are correct
			size = A.getNumOfRows()

			{l, u, p} = A.decompose()
			pb = p.times(b)
			y = Matrix.createBlankMatrix(size, 1)

			# Use inner arrays for clarity
			Am = A._m
			pbm = pb._m
			Lm = l._m	
			Um = u._m
			ym = y._m

			# Solve Ly = Pb where y = Ux using forward substitution
			for rowIndex in [0...size]
				ym[rowIndex][0] = pbm[rowIndex][0]
				for colIndex in [0...rowIndex]
					ym[rowIndex][0] -= Lm[rowIndex][colIndex] * ym[colIndex][0]
				ym[rowIndex][0] /= Lm[rowIndex][rowIndex]

			x = Matrix.createBlankMatrix(size, 1)
			xm = x._m

			# Solve Ux = y using backward substitution
			for rowIndex in [size-1..0]
				xm[rowIndex][0] = ym[rowIndex][0]
				for colIndex in [rowIndex+1...size]
					xm[rowIndex][0] -= Um[rowIndex][colIndex] * xm[colIndex][0]
				xm[rowIndex][0] /= Um[rowIndex][rowIndex]

			x

		# @param (int) size
		# @return (Matrix) The identity matrix of given size.
		@createIdentityMatrix = (size) ->
			assert(size).withName('size').notNegative size
			if size is 0
				return new Matrix()
			m = (((if (j == i) then 1 else 0) for j in [0...size]) for i in [0...size])
			return new Matrix(m)

		@createBlankMatrix = (numOfRows, numOfCols) ->
			if not numOfCols?
				numOfCols = numOfRows
			assert(numOfRows).withName('numOfRows').notNegative numOfRows
			assert(numOfCols).withName('numOfCols').notNegative numOfCols
			b = ((0 for j in [0...numOfCols]) for i in [0...numOfRows])
			return new Matrix(b)

		###
		[rows][columns]
		e.g.
		[[ 2, 3, 2, 1]
		 [ 4, 8, 7, 3]
		 [ 2, 1, 0, 2]
		 [ - 4, - 4, 1, 2]]
		###
		_m: [[]]

		constructor: (array) ->
			# TODO assert that all rows are arrays of equal length
			if array?
				assert(array).withName('Matrix constructor array').isArray()
				assert(array[0]).withName('Matrix constructor inner array').isArray()
				@_m = array

		# Multiply this matrix with another matrix.
		# @param (Matrix) m2 Another matrix, with a number of rows equal to the number of columns in this matrix.
		# @return (Matrix)
		times: (m2) ->
			if @getNumOfColumns() isnt m2.getNumOfRows()
				throw {
					name: 'IllegalArgumentException'
					message: "Can't multiply a #{@getDimensions()} matrix by a #{m2.getDimensions()} matrix."
				}

			# work with the inner array
			n = m2._m

			# initialise result
			r = ((0 for [0...m2.getNumOfColumns()]) for [0...@getNumOfRows()  ])

			for i in [0...@getNumOfRows()	]
				for j in [0...m2.getNumOfColumns()]
					for k in [0...@getNumOfColumns()]
						r[i][j] += @_m[i][k] * n[k][j]
			return new Matrix(r)

		# @return (int)
		getNumOfColumns: () ->
			@_m[0].length

		# @return ([int])
		getNumOfRows: () ->
			if @_m[0].length > 0
				@_m.length
			else # special case for empty matrix
				0

		# @return ([int])
		getDimensions: () ->
			[@getNumOfRows(), @getNumOfColumns() ]

		# @return (boolean)
		isSquare: () ->
			@getNumOfRows() is @getNumOfColumns()

		# Decompose this matrix into lower and upper triangular matrices.
		# @throws SingularMatrixException
		# @return ({l: Matrix, u: Matrix})
		decompose: () ->
			if not @isSquare()
				throw {
					name: 'NotImplementedException',
					message: 'LU Decomposition not implemented for non-square matrices.'
				}

			size = @getNumOfRows()
			if(size is 0)
				return {l: new Matrix(), u: new Matrix(), p: new Matrix() }

			# initialise l and u
			l = Matrix.createIdentityMatrix(size)._m
			u = @copy()._m
			p = Matrix.createIdentityMatrix(size)._m

			###
			Gaussian elimination w / partial pivoting
			###
			for i in [0...size - 1] # reduce size of square subset each iteration
				# choose pivot
				pivotRowIndex = i
				maxFirstElement = u[i][i]
				for r in [i...size] # for rows in sub-square
					if u[r][i] > maxFirstElement
						maxFirstElement = u[r][i]
						pivotRowIndex = r
				if maxFirstElement is 0
					throw {
						name: 'SingularMatrixException',
						message: 'Singular matrix'
						cause: @
					}

				# row swap
				if pivotRowIndex isnt i
					for e in [i...size] # swap rows in u
						[u[i][e], u[pivotRowIndex][e]] = [u[pivotRowIndex][e], u[i][e]]
					for e in [0...i] # swap rows in l
						[l[i][e], l[pivotRowIndex][e]] = [l[pivotRowIndex][e], l[i][e]]
					[p[i], p[pivotRowIndex]] = [p[pivotRowIndex], p[i]]

				# Gaussian Elimination
				for j in [i + 1...size] # for every row in this sub-square
					l[j][i] = u[j][i] / u[i][i] # work out the factor to make first element zero
					for k in [i...size] # for each element in row in sub-square
						u[j][k] -= l[j][i] * u[i][k] # row = row - factor*topRowInSubset

			return {l: new Matrix(l), u: new Matrix(u), p: new Matrix(p) }

		set: (row, col) ->
			if not col?
				col = 0
			m = @_m
			to: (value) ->
				m[row][col] = value

		get: (row, col) ->
			if not col?
				col = 0
			@_m[row][col]

		# @return (Matrix)
		copy: () ->
			return new Matrix(copy(@_m) )

		# @param (Matrix)
		# @return (boolean)
		equals: (otherMatrix) ->
			utils.deepEquals(@_m, otherMatrix._m)

		toString: () ->
			@_m.toString()

		valueOf: () ->
			@_m.valueOf()

