const path = require('path')
const fs = require('fs');

var Application = require('spectron').Application

const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')

chai.should()
chai.use(chaiAsPromised)

const electronPath = require('electron')

console.log("path", path.join(__dirname, '..'))
const test_helper = {
  name: (location, component) => component ? `${location}: ${component}` : location,
  setup: (fn, opt) => function () {
    this.timeout(opt && opt.timeout ? opt.timeout : 0)

    if (opt && opt.open_before === 'each') {
      beforeEach(function () {
        this.app = new Application({
          path: electronPath,
          args: [path.join(__dirname, '..')]
        })
        return this.app.start()
      })
    }
    else {
      before(function () {
        this.app = new Application({
          path: electronPath,
          args: [path.join(__dirname, '..')]
        })
        return this.app.start()
      })
    }

    beforeEach(function () {
      chaiAsPromised.transferPromiseness = this.app.transferPromiseness
    })

    const delay = time => new Promise(resolve => setTimeout(resolve, time));
    const appPath = path.resolve(__dirname, '../../entry.js');
    if (opt && opt.close_after === 'each') {
      afterEach(function () {
        if (this.app && this.app.isRunning()) {
          return this.app.stop()
        }
      })
    }
    else if (opt && opt.close_after === true) {
      after(function () {
        if (this.app && this.app.isRunning()) {
          return this.app.stop()
        }
        return undefined;
      })
    }

    fn();
  }
}

// retrieve and run all sub-directory tests
const test_dirs = process.env.npm_config_test ?
  [process.env.npm_config_test] :
  fs.readdirSync(__dirname, { withFileTypes: true })
    .filter(f => f.isDirectory())
    .map(f => f.name)

test_dirs
  .forEach(f => require(path.join(__dirname, f))(test_helper))
