import {Matrixy} from 'matrixy';
import createEquationBuilder from '../equation_builder';

const {createMatrix} = Matrixy;

const blankThreeNodeEquation = {
  nodalAdmittances: createMatrix([[0, 0],
                                  [0, 0]]),
  inputs: createMatrix([[0],
                        [0]])
};
const arraysForBlankThreeNode = [blankThreeNodeEquation.nodalAdmittances(), blankThreeNodeEquation.inputs()];

describe('Equation Builder initialisation', function() {
  it('should initialise to a blank equation', function() {
    const {getEquation} = createEquationBuilder({
            numOfNodes: 3
          }),
          {nodalAdmittances, inputs} = getEquation(),
          arrays = [nodalAdmittances(), inputs()];
    expect(arrays).to.eql(arraysForBlankThreeNode);
  });

  it('should accept number of voltage sources as an optional parameter', function() {
    const {getEquation} = createEquationBuilder({
            numOfNodes: 2,
            numOfVSources: 1
          }),
          {nodalAdmittances, inputs} = getEquation(),
          arrays = [nodalAdmittances(), inputs()];
    expect(arrays).to.eql(arraysForBlankThreeNode);
  });

  it('should throw an exception if given a number of nodes < 2', function() {
    expect(() => {
      createEquationBuilder({
        numOfNodes: 1
      });
    }).to.throw(/.*Number of nodes.*/);
  });

  it('should throw an exception if given a number of voltage sources < 0', function() {
    expect(() => {
      createEquationBuilder({
        numOfNodes: 2,
        numOfVSources: -1
      });
    }).to.throw(/.*Number of voltage sources.*/);
  });
});

describe('Stamping:', function() {
  describe('stamping a resistance', function() {
    it('should stamp a resistance into the nodal admittance matrix', function() {
      const {stampResistor, getEquation} = createEquationBuilder({ numOfNodes: 3 });
      stampResistor(5, 1, 2);
      const {nodalAdmittances, inputs} = getEquation();
      expect(nodalAdmittances()).to.eql([[1 / 5, -1 / 5],
                                         [-1 / 5, 1 / 5]]);
      expect(inputs()).to.eql(blankThreeNodeEquation.inputs());
    });

    it('should be additive', function() {
      const {stampResistor, getEquation} = createEquationBuilder({ numOfNodes: 3 });
      stampResistor(5, 0, 2);
      stampResistor(5, 1, 2);
      expect(getEquation().nodalAdmittances()).to.eql([[1 / 5, -1 / 5],
                                                       [-1 / 5, 2 / 5]]);
    });

    it('should throw an exception if resistance is zero', function() {
      const {stampResistor} = createEquationBuilder({ numOfNodes: 3 });
      expect(() => {
        stampResistor(0, 1, 2);
      }).to.throw(/.*resistance.*/);
    });

    it('should not stamp a negative resistance', function() {
      const {stampResistor} = createEquationBuilder({ numOfNodes: 3 });
      expect(() => {
        stampResistor(-1, 1, 2);
      }).to.throw(/.*resistance.*/);
    });
  });

  describe('stamping a voltage source', function() {
    it('should stamp a voltage into the input vector', function() {
      const {stampVoltageSource, getEquation} = createEquationBuilder({
        numOfNodes: 3,
        numOfVSources: 1
      });
      stampVoltageSource(5, 1, 2);
      expect(getEquation().inputs()).to.eql([[0],
                                             [0],
                                             [5]]);
    });

    it('should stamp into the augmented part of the nodal admittance matrix', function() {
      const {stampVoltageSource, getEquation} = createEquationBuilder({
        numOfNodes: 3,
        numOfVSources: 1
      });
      stampVoltageSource(5, 1, 2);
      expect(getEquation().nodalAdmittances()).to.eql([[0, 0, 1],
                                                       [0, 0, -1],
                                                       [1, -1, 0]]);
    });

    it('should not stamp more than the specified number of voltage sources', function() {
      const {stampVoltageSource} = createEquationBuilder({
        numOfNodes: 3,
        numOfVSources: 1
      });
      stampVoltageSource(5, 0, 1);
      expect(() => {
        stampVoltageSource(5, 0, 1);
      }).to.throw(/.*Number of voltage sources stamped.*/);
    });
  });

  describe('stamping a current source', function() {
    it('should stamp a current source', function() {
      const {stampCurrentSource, getEquation} = createEquationBuilder({
        numOfNodes: 3
      });
      stampCurrentSource(5, 1, 2);
      const {nodalAdmittances, inputs} = getEquation();
      expect(inputs()).to.eql([[-5],
                               [5]]);
      expect(nodalAdmittances()).to.eql(blankThreeNodeEquation.nodalAdmittances());
    });
  });

  describe('controlled sources', function() {
    describe('stamping a current controlled current source', function() {
      it('should stamp a CCCS', function() {
        const {stampCCCS, getEquation} = createEquationBuilder({
          numOfNodes: 4,
          numOfVSources: 1
        });
        stampCCCS(10, 1, 2, 2, 3);
        expect(getEquation().nodalAdmittances()).to.eql([[0, 0, 0, 1],
                                                         [0, 0, 0, 9],
                                                         [0, 0, 0, -10],
                                                         [1, -1, 0, 0]]);
      });
    });

    describe('stamping a current controlled voltage source', function() {
      it('should stamp a CCVS', function() {
        const {stampCCVS, getEquation} = createEquationBuilder({
          numOfNodes: 4,
          numOfVSources: 2
        });
        stampCCVS(10, 1, 2, 2, 3);
        expect(getEquation().nodalAdmittances()).to.eql([[0, 0, 0, 1, 0],
                                                         [0, 0, 0, -1, 1],
                                                         [0, 0, 0, 0, -1],
                                                         [1, -1, 0, 0, 0],
                                                         [0, 1, -1, -10, 0]]);
      });
    });

    describe('stamping a voltage controlled current source', function() {
      it('should stamp a VCCS', function() {
        const {stampVCCS, getEquation} = createEquationBuilder({
          numOfNodes: 4
        });
        stampVCCS(10, 1, 2, 2, 3);
        expect(getEquation().nodalAdmittances()).to.eql([[0, 0, 0],
                                                         [10, -10, 0],
                                                         [-10, 10, 0]]);
      });
    });

    describe('stamping a voltage controlled voltage source', function() {
      it('should stamp a VCVS', function() {
        const {stampVCVS, getEquation} = createEquationBuilder({
          numOfNodes: 4,
          numOfVSources: 1
        });
        stampVCVS(10, 1, 2, 2, 3);
        expect(getEquation().nodalAdmittances()).to.eql([[0, 0, 0, 0],
                                                         [0, 0, 0, 1],
                                                         [0, 0, 0, -1],
                                                         [-10, 11, -1, 0]]);
      });
    });
  });
});

describe('solve', function() {
  it('should solve a simple circuit with no voltage sources', function() {
    const {stampResistor, stampCurrentSource, solve} = createEquationBuilder({
      numOfNodes: 2
    });
    stampCurrentSource(1, 0, 1);
    stampResistor(100, 1, 0);
    const solution = solve();
    expect(solution()).to.eql([[100]]);
  });

  it('should solve a simple circuit with a voltage source', function() {
    const {stampResistor, stampVoltageSource, stampCurrentSource, solve} = createEquationBuilder({
      numOfNodes: 3,
      numOfVSources: 1
    });
    stampCurrentSource(1, 0, 1);
    stampVoltageSource(0, 1, 2);
    stampResistor(100, 2, 0);
    const solution = solve();
    expect(solution()).to.eql([[100], [100], [1]]);
  });
});
