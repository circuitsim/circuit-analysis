{Matrixy} = require 'matrixy'
{createEquationBuilder} = require '../src/equation_builder'

{createMatrix} = Matrixy

blankThreeNodeEquation =
  nodalAdmittances: createMatrix [[0, 0]
                                  [0, 0]]
  inputs: createMatrix [[0]
                        [0]]

arraysForBlankThreeNode = [blankThreeNodeEquation.nodalAdmittances(), blankThreeNodeEquation.inputs()]

describe 'Equation Builder:', ->
  it 'should initialise to a blank equation', ->
    {getEquation} = createEquationBuilder { numOfNodes: 3}

    {nodalAdmittances, inputs} = getEquation()
    arrays = [nodalAdmittances(), inputs()]

    expect(arrays ).to.eql arraysForBlankThreeNode

  it 'should accept number of voltage sources as an optional parameter', ->
    {getEquation} = createEquationBuilder {numOfNodes: 2, numOfVSources: 1}

    {nodalAdmittances, inputs} = getEquation()
    arrays = [nodalAdmittances(), inputs()]

    expect(arrays ).to.eql arraysForBlankThreeNode

  it 'should throw an exception if given a number of nodes < 2', ->
    expect( -> createEquationBuilder {numOfNodes: 1} ).to.throw /.*Number of nodes.*/

  it 'should throw an exception if given a number of voltage sources < 0', ->
    expect( -> createEquationBuilder {numOfNodes: 2, numOfVSources: - 1} ).to.throw /.*Number of voltage sources.*/

describe 'Stamping:', ->

  it 'should not accept out of bounds nodes', ->
    {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
    between = stamp(10).ohms.between
    expect( -> between(0, 3) ).to.throw /.*to node.*/
    expect( -> between( - 1, 2) ).to.throw /.*from node.*/

  describe 'stamping a resistance', ->
    it 'should stamp a resistance into the nodal admittance matrix', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      stamp(5).ohms.between(1, 2)
      expect(getEquation().nodalAdmittances()).to.eql [[1/5, - 1/5]
                                                       [ - 1/5, 1/5]]
      expect(getEquation().inputs()).to.eql blankThreeNodeEquation.inputs()

    it 'should be additive', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      stamp(5).ohms.between(0, 2)
      stamp(5).ohms.between(1, 2)
      expect(getEquation().nodalAdmittances()).to.eql [[1/5, - 1/5]
                                                       [ - 1/5, 2/5]]

    it 'should throw an exception if resistance is zero', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      expect(-> stamp(0).ohms.between(1, 2) ).to.throw /.*resistance.*/

    it 'should not stamp a negative resistance', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      expect( -> stamp( - 1).ohms.between(1, 2) ).to.throw /.*conductance.*/

  describe 'stamping a conductance', ->
    it 'should stamp a conductance', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      stamp(5).siemens.between(1, 2)
      expect(getEquation().nodalAdmittances()).to.eql [[5, - 5]
                                                       [ - 5, 5]]
      expect(getEquation().inputs()).to.eql blankThreeNodeEquation.inputs()

    it 'should be additive', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      stamp(5).siemens.between(0, 2)
      stamp(5).siemens.between(1, 2)
      expect(getEquation().nodalAdmittances()).to.eql [[5, - 5]
                                                       [ - 5, 10]]

    it 'should not stamp a negative conductance', ->
      {stamp} = createEquationBuilder { numOfNodes: 2}
      expect(-> stamp( - 1).siemens.between(0, 1) ).to.throw /.*conductance.*/

  describe 'stamping a voltage source', ->
    it 'should stamp a voltage into the input vector', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
      stamp(5).volts.from(1).to(2)
      expect(getEquation().inputs() ).to.eql [[0]
                                              [0]
                                              [5]]

    it 'should stamp into the augmented part of the nodal admittance matrix', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
      stamp(5).volts.from(1).to(2)
      expect(getEquation().nodalAdmittances()).to.eql [[0, 0, 1]
                                                       [0, 0, -1]
                                                       [ 1, -1, 0]]

    it 'should not stamp more than the specified number of voltage sources', ->
      {stamp} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}
      stamp(5).volts.from(0).to(1)
      expect( -> stamp(5).volts.from(0).to(1) ).to.throw /.*Number of voltage sources stamped.*/

  describe 'stamping a current source', ->
    it 'should stamp a current source', ->
      {stamp, getEquation} = createEquationBuilder { numOfNodes: 3}
      stamp(5).amps.from(1).to(2)
      expect(getEquation().inputs()).to.eql [[ - 5]
                                             [5]]
      expect(getEquation().nodalAdmittances()).to.eql blankThreeNodeEquation.nodalAdmittances()

  describe 'controlled sources', ->
    describe 'stamping a current controlled current source', ->
      it 'should stamp a CCCS', ->
        {stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 1}

        stamp.a.gain.of(10).multiplying.a.current.from(1).to(2)
          .controlling.a.currentSource.from(2).to(3)

        expect(getEquation().nodalAdmittances()).to.eql [[ 0, 0, 0, 1 ]
                                                         [ 0, 0, 0, 9 ]
                                                         [ 0, 0, 0, - 10 ]
                                                         [ 1, -1, 0, 0 ]]

    describe 'stamping a current controlled voltage source', ->
      it 'should stamp a CCVS', ->
        {stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 2}

        stamp.a.gain.of(10).multiplying.a.current.from(1).to(2)
          .controlling.a.voltageSource.from(2).to(3)

          expect(getEquation().nodalAdmittances()).to.eql [[ 0, 0, 0, 1, 0 ]
                                                           [ 0, 0, 0, -1, 1 ]
                                                           [ 0, 0, 0, 0, -1 ]
                                                           [ 1, -1, 0, 0, 0 ]
                                                           [ 0, 1, -1, -10, 0 ]]


    describe 'stamping a voltage controlled current source', ->
      it 'should stamp a VCCS', ->
        {stamp, getEquation} = createEquationBuilder { numOfNodes: 4}

        stamp.a.gain.of(10).multiplying.a.voltage.from(1).to(2)
          .controlling.a.currentSource.from(2).to(3)

        expect(getEquation().nodalAdmittances() ).to.eql [[ 0, 0, 0]
                                                          [ 10, - 10, 0]
                                                          [ - 10, 10, 0]]

    describe 'stamping a voltage controlled voltage source', ->
      it 'should stamp a VCVS', ->
        {stamp, getEquation} = createEquationBuilder { numOfNodes: 4, numOfVSources: 1}

        stamp.a.gain.of(10).multiplying.a.voltage.from(1).to(2)
          .controlling.a.voltageSource.from(2).to(3)

        expect(getEquation().nodalAdmittances() ).to.eql [[ 0, 0, 0, 0 ]
                                                          [ 0, 0, 0, 1 ]
                                                          [ 0, 0, 0, -1 ]
                                                          [ - 10, 11, -1, 0 ]]

describe 'solve', ->
  it 'should solve a simple circuit with no voltage sources', ->
    {stamp, solve} = createEquationBuilder { numOfNodes: 2}

    stamp(1).amps.from(0).to(1);
    stamp(100).ohms.between(1, 0);

    solution = solve()

    expect(solution()).to.eql [[100]] # 100 volts

  it 'should solve a simple circuit with a voltage source', ->
    {stamp, solve} = createEquationBuilder { numOfNodes: 3, numOfVSources: 1}

    stamp(1).amps.from(0).to(1);
    stamp(0).volts.from(1).to(2);
    stamp(100).ohms.between(2, 0);

    solution = solve()

    expect(solution()).to.eql [[100], [100], [1]] # 100 volts, 1 amp
