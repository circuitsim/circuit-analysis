chai = require('chai')
global.expect = chai.expect

chai.config.includeStack = true

chaiStats = require('chai-stats');
chai.use(chaiStats)