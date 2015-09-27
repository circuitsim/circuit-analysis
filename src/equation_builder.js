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
  expect(numOfNodes, 'Number of nodes')
    .to.be.at.least(MIN_NUM_OF_NODES);
  expect(numOfVSources, 'Number of voltage sources')
    .to.be.at.least(0);

  const size = numOfNodes + numOfVSources - 1,
        {nodalAdmittances, inputs} = createBlankEquation(size);
  let numOfVoltageSourcesStamped = 0;

  const stampNodalAdmittanceMatrix = (row, col, x) => {
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
        stampConductance = (conductance, node1, node2) => {
          stampNodalAdmittanceMatrix(node1, node1, conductance);
          stampNodalAdmittanceMatrix(node2, node2, conductance);
          stampNodalAdmittanceMatrix(node1, node2, -conductance);
          return stampNodalAdmittanceMatrix(node2, node1, -conductance);
        };

  const stampResistor = (resistance, node1, node2) => {
          expect(resistance, 'resistance')
            .to.be.above(0);
          const conductance = 1 / resistance;
          stampConductance(conductance, node1, node2);
        },

        stampVoltageSource = (voltage, fromNode, toNode) => {
          expect(numOfVoltageSourcesStamped, 'Number of voltage sources stamped')
            .to.be.lessThan(numOfVSources);
          const vIndex = numOfNodes + numOfVoltageSourcesStamped;
          numOfVoltageSourcesStamped++;
          stampNodalAdmittanceMatrix(vIndex, fromNode, 1);
          stampNodalAdmittanceMatrix(vIndex, toNode, -1);
          stampNodalAdmittanceMatrix(fromNode, vIndex, 1);
          stampNodalAdmittanceMatrix(toNode, vIndex, -1);
          stampInputVector(vIndex, voltage);
          return vIndex;
        },

        stampCurrentSource = (current, fromNode, toNode) => {
          stampInputVector(fromNode, -current);
          return stampInputVector(toNode, current);
        },

        stampCCCS = (
            gain,
            fromControlNode, toControlNode,
            fromSourceNode, toSourceNode
          ) => {
          const vIndexControl = stampVoltageSource(0, fromControlNode, toControlNode);
          stampNodalAdmittanceMatrix(fromSourceNode, vIndexControl, gain);
          stampNodalAdmittanceMatrix(toSourceNode, vIndexControl, -gain);
        },

        stampCCVS = (
            gain,
            fromControlNode, toControlNode,
            fromSourceNode, toSourceNode
          ) => {
          const vIndexControl = stampVoltageSource(0, fromControlNode, toControlNode);
          const vIndexSource = stampVoltageSource(0, fromSourceNode, toSourceNode);
          stampNodalAdmittanceMatrix(vIndexSource, vIndexControl, -gain);
        },

        stampVCCS = (
            gain,
            fromControlNode, toControlNode,
            fromSourceNode, toSourceNode
          ) => {
          stampNodalAdmittanceMatrix(fromSourceNode, fromControlNode, gain);
          stampNodalAdmittanceMatrix(fromSourceNode, toControlNode, -gain);
          stampNodalAdmittanceMatrix(toSourceNode, fromControlNode, -gain);
          stampNodalAdmittanceMatrix(toSourceNode, toControlNode, gain);
        },

        stampVCVS = (
            gain,
            fromControlNode, toControlNode,
            fromSourceNode, toSourceNode
          ) => {
          const vIndexSource = stampVoltageSource(0, fromSourceNode, toSourceNode);
          stampNodalAdmittanceMatrix(vIndexSource, fromControlNode, -gain);
          stampNodalAdmittanceMatrix(vIndexSource, toControlNode, gain);
        };

  return {
    stampResistor,
    stampVoltageSource,
    stampCurrentSource,
    stampCCCS,
    stampCCVS,
    stampVCCS,
    stampVCVS,

    getEquation: () => {
      return {nodalAdmittances, inputs};
    },
    solve: () => {
      return solve(nodalAdmittances, inputs);
    }
  };
}
