Matrix = require '../src/matrix'

emptyMatrix = new Matrix()
m1 = new Matrix([[1, 2, 3]
				 				 [4, 5, 6]])
m2 = new Matrix([[ 7, 8]
				 				 [ 9, 10]
				 				 [11, 12]])
squareMatrix = new Matrix([[1, 2]
						 						 	 [3, 4]])
fiveMatrix = new Matrix([[4, 7, 7, 2, 0]
												 [3, 4, 8, 8, 0]
												 [1, 5, 2, 9, 6]
												 [6, 1, 2, 2, 1]
												 [6, 4, 8, 2, 8]])
singularMatrix = new Matrix([[0, 1]
														 [0, 1]])

describe 'Matrix', ->
	describe 'Dimensions', ->
		it 'should return correct dimensions', ->
			expect(m1.getDimensions() ).to.eql([2, 3])
		it 'should return correct dimensions for an empty matrix', ->
			expect(emptyMatrix.getDimensions() ).to.eql([0, 0])
		it 'should return the correct number of columns', ->
			expect(m1.getNumOfColumns() ).to.equal(3)
		it 'should return the correct number of rows', ->
			expect(m1.getNumOfRows() ).to.equal(2)
		it 'should return the correct number of columns for an empty matrix', ->
			expect(emptyMatrix.getNumOfColumns() ).to.equal(0)
		it 'should return the correct number of rows for an empty matrix', ->
			expect(emptyMatrix.getNumOfRows() ).to.equal(0)

	describe 'isSquare()', ->
		it 'should return true if the matrix is square', ->
			expect(squareMatrix.isSquare() ).to.be.true
		it 'should return false if the matrix isn\'t square', ->
			expect(m1.isSquare() ).to.be.false

	describe 'createIdentityMatrix()', ->
		it 'should create an identity matrix', ->
			expect(Matrix.createIdentityMatrix(3)._m).to.eql([[1, 0, 0]
																 												[0, 1, 0]
																 												[0, 0, 1]])
		it 'should create an empty identity matrix', ->
			expect(Matrix.createIdentityMatrix(0)._m).to.eql([[]])
		it 'should return illegal argument exception if size < 0', ->
			expect(-> Matrix.createIdentityMatrix( - 1) ).to.throw("Expected >0. Was: -1")

	describe 'createBlankMatrix()', ->
		it 'should create a 2x2 matrix of all zeros', ->
			expect(Matrix.createBlankMatrix(2, 2)._m).to.eql([[0, 0]
																												[0, 0]])
		it 'should return illegal argument exception if size < 0', ->
			expect(-> Matrix.createBlankMatrix( - 1) ).to.throw("Expected >0. Was: -1")

	describe 'equals()', ->
		it 'should return true for equal matrices', ->
			expect(m1.equals(new Matrix([[1, 2, 3]
				 													 [4, 5, 6]]) ) ).to.be.true
		it 'should return false for non-equal matrices', ->
		expect(m1.equals(m2) ).to.be.false

	describe 'copy()', ->
		it 'should copy itself', ->
			expect(m1.copy()._m).to.eql(m1._m)
		it 'should create a copy rather than a reference', ->
			copy = m1.copy()
			copy._m[0][0] = 16
			expect(m1._m[0][0]).to.eql(1)

	describe 'set().to() and get()', ->
		it 'should set an entry in the matrix', ->
			m = m1.copy()
			m.set(0, 0).to(6)
			expect(m.get(0, 0) ).to.eql(6)

	describe 'Multiplication', ->
		it 'should throw an error if the number of rows/columns don\'t match', ->
			expect(-> m1.times(emptyMatrix) ).to.throw("Can't multiply a 2,3 matrix by a 0,0 matrix.")
		it 'should multiply two matrices of different sizes', ->
			expect(m1.times(m2)._m).to.eql([[ 58, 64]
										 									[139, 154]])
		it 'should multiply a 3x3 by a 3x1 matrix to form a non-square matrix', ->
			threeByThree = new Matrix([[0, 0, 1]
																 [0, 1, 0]
																 [1, 0, 0]])
			threeByOne = new Matrix([[6]
															 [ - 4]
															 [27]])
			expect(threeByThree.times(threeByOne)._m).to.eql([[27]
																												[ - 4]
																												[6]])

	describe 'LU Decomposition', ->
		it 'should decompose an empty matrix into empty {l,u,p}', ->
			{l, u, p} = emptyMatrix.decompose()
			expect(l).to.be.empty
			expect(u).to.be.empty
			expect(p).to.be.empty
		it 'should return {l,u,p} where LU == PA for integer solutions', ->
			{l, u, p} = squareMatrix.decompose()
			expect(l.times(u) ).to.eql(p.times(squareMatrix) )
		it 'should return {l,u,p} where LU ~= PA for floating point solutions', ->
			{l, u, p} = fiveMatrix.decompose()
			expect(l.times(u) ).to.almost.eql(p.times(fiveMatrix), 14)
		it 'should return a lower triangular matrix', ->
			{l, u, p} = squareMatrix.decompose()
			expect(l._m[0][1]).to.equal(0)
		it 'should return an upper triangular matrix', ->
			{l, u, p} = squareMatrix.decompose()
			expect(u._m[1][0]).to.equal(0)
		it 'should throw an exception for non-square matrices', ->
			expect(-> m1.decompose() ).to.throw("LU Decomposition not implemented for non-square matrices.")
		describe 'Singular matrix handling', ->
			it 'should throw an exception for singular matrices', ->
				expect(-> singularMatrix.decompose() ).to.throw("Singular matrix")
			it 'should throw an exception which contains the problem matrix', ->
				try
					singularMatrix.decompose()
				catch error

	describe 'Equation solver', ->
		it 'should solve a matrix equation of the form Ax=b for x', ->
			A = new Matrix([[1, 1, 1]
											[0, 2, 5]
											[2, 5, - 1]])
			b = new Matrix([[6]
											[ - 4]
											[27]])
			expect(Matrix.solve(A, b)._m ).to.eql([[5]
																						 [3]
																						 [ - 2]])
