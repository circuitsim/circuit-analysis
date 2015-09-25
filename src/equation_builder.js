import {Matrixy} from 'matrixy';
import {expect} from 'chai';

const{createBlankMatrix, set, solve} = Matrixy;
const MIN_NUM_OF_NODES = 2;

const createBlankEquation = (size) => {
  return {
    nodalAdmittances: createBlankMatrix(size),
    inputs: createBlankMatrix(size, 1)
  };
};

export default function({numOfNodes, numOfVSources = 0}) {
  expect(numOfNodes, 'Number of nodes').to.be.at.least(MIN_NUM_OF_NODES);
  expect(numOfVSources, 'Number of voltage sources').to.be.at.least(0);
  let numOfVoltageSourcesStamped = 0;
  const size = numOfNodes + numOfVSources - 1,
        {nodalAdmittances, inputs} = createBlankEquation(size),
        stampNodalAdmittanceMatrix = (row, col, x) => {
          if (row !== 0 && col !== 0) {
            row--;
            col--;
            return nodalAdmittances(set(row, col).plusEquals(x));
          }
        },
        stampInputVector = (row, x) => {
          if (row !== 0) {
            row--;
            return inputs(set(row, 0).plusEquals(x));
          }
        },
        stampConductance = (conductance) => {
          return function(node1, node2) {
            expect(conductance, 'conductance').to.be.at.least(0);
            stampNodalAdmittanceMatrix(node1, node1, conductance);
            stampNodalAdmittanceMatrix(node2, node2, conductance);
            stampNodalAdmittanceMatrix(node1, node2, -conductance);
            return stampNodalAdmittanceMatrix(node2, node1, -conductance);
          };
        },
        stampResistance = (resistance) => {
          return function(node1, node2) {
            expect(resistance, 'resistance').to.not.equal(0);
            const conductance = 1 / resistance;
            return stampConductance(conductance)(node1, node2);
          };
        },
        stampVoltageSource = (voltage) => {
          return function(fromNode, toNode) {
            expect(numOfVoltageSourcesStamped, 'Number of voltage sources stamped').to.be.lessThan(numOfVSources);
            const vIndex = numOfNodes + numOfVoltageSourcesStamped;
            numOfVoltageSourcesStamped++;
            stampNodalAdmittanceMatrix(vIndex, fromNode, 1);
            stampNodalAdmittanceMatrix(vIndex, toNode, -1);
            stampNodalAdmittanceMatrix(fromNode, vIndex, 1);
            stampNodalAdmittanceMatrix(toNode, vIndex, -1);
            stampInputVector(vIndex, voltage);
            return vIndex;
          };
        },
        stampCurrentSource = (current) => {
          return function(fromNode, toNode) {
            stampInputVector(fromNode, -current);
            return stampInputVector(toNode, current);
          };
        },
        stampControlledSource = (gain) => {
          return {
            CC: function(fromControlNode, toControlNode) {
              const vIndexControl = stampVoltageSource(0)(fromControlNode, toControlNode);
              return {
                CS: function(fromSourceNode, toSourceNode) {
                  stampNodalAdmittanceMatrix(fromSourceNode, vIndexControl, gain);
                  return stampNodalAdmittanceMatrix(toSourceNode, vIndexControl, -gain);
                },
                VS: function(fromSourceNode, toSourceNode) {
                  const vIndexSource = stampVoltageSource(0)(fromSourceNode, toSourceNode);
                  return stampNodalAdmittanceMatrix(vIndexSource, vIndexControl, -gain);
                }
              };
            },
            VC: function(fromControlNode, toControlNode) {
              return {
                CS: function(fromSourceNode, toSourceNode) {
                  stampNodalAdmittanceMatrix(fromSourceNode, fromControlNode, gain);
                  stampNodalAdmittanceMatrix(fromSourceNode, toControlNode, -gain);
                  stampNodalAdmittanceMatrix(toSourceNode, fromControlNode, -gain);
                  return stampNodalAdmittanceMatrix(toSourceNode, toControlNode, gain);
                },
                VS: function(fromSourceNode, toSourceNode) {
                  const vIndexSource = stampVoltageSource(0)(fromSourceNode, toSourceNode);
                  stampNodalAdmittanceMatrix(vIndexSource, fromControlNode, -gain);
                  return stampNodalAdmittanceMatrix(vIndexSource, toControlNode, gain);
                }
              };
            }
          };
        },
        validateNodes = (stampFunction) => {
          return function(fromNode, toNode) {
            expect(fromNode, 'from node').to.be.at.least(0).and.lessThan(numOfNodes);
            expect(toNode, 'to node').to.be.at.least(0).and.lessThan(numOfNodes);
            return stampFunction(fromNode, toNode);
          };
        },
        directional = (functionUsingNodes) => {
          return {
            from: function(fromNode) {
              return {
                to: function(toNode) {
                  return validateNodes(functionUsingNodes)(fromNode, toNode);
                }
              };
            }
          };
        },
        nonDirectional = (functionUsingNodes) => {
          return {
            between: function(fromNode, toNode) {
              return validateNodes(functionUsingNodes)(fromNode, toNode);
            }
          };
        },
        stampGain = (gain) => {
          const {CC, VC} = stampControlledSource(gain);
          const extendApi = (controllingType) => {
            return function(fromNode, toNode) {
              const {CS, VS} = controllingType(fromNode, toNode);
              return {
                controlling: {
                  a: {
                    currentSource: directional(CS),
                    voltageSource: directional(VS)
                  }
                }
              };
            };
          };
          return {
            multiplying: {
              a: {
                current: directional(extendApi(CC)),
                voltage: directional(extendApi(VC))
              }
            }
          };
        },
        stamp = (value) => {
          return {
            ohms: nonDirectional(stampResistance(value)),
            siemens: nonDirectional(stampConductance(value)),
            volts: directional(stampVoltageSource(value)),
            amps: directional(stampCurrentSource(value))
          };
        };

  stamp.a = {
    gain: {
      of: stampGain
    }
  };
  return {
    stamp: stamp,
    getEquation: function() {
      return {
        nodalAdmittances: nodalAdmittances,
        inputs: inputs
      };
    },
    solve: function() {
      return solve(nodalAdmittances, inputs);
    }
  };
}
