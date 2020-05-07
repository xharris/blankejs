module.exports = function (helper) {
  const { name, setup } = helper;

  describe(name('Application'), setup(function () {
    it('opens the IDE', function () {
      return this.app.client.waitUntilWindowLoaded()
        .getWindowCount().should.eventually.have.at.least(1)
        .browserWindow.isVisible().should.eventually.be.true
        .browserWindow.getBounds().should.eventually.have.property('width').and.be.above(0)
        .browserWindow.getBounds().should.eventually.have.property('height').and.be.above(0)
        .getText(".blankejs-toasts .toast-container .content")
        .should.eventually.match(/No updates|Update available/)
    })

    it('checks for updates', function () {
      return this.app.client.waitUntilWindowLoaded()
        .getWindowCount().should.eventually.have.at.least(1)
        .browserWindow.isVisible().should.eventually.be.true
        .browserWindow.getBounds().should.eventually.have.property('width').and.be.above(0)
        .browserWindow.getBounds().should.eventually.have.property('height').and.be.above(0)
        .getText(".blankejs-toasts .toast-container .content")
        .should.eventually.match(/No updates|Update available/)
    })
  }, {
    timeout: 10000,
    close_after: true
  }))

  describe(name('Application', 'Window buttons'), setup(function () {
    it('minimizes', function () {
      return this.app.client.waitUntilWindowLoaded()
        .getWindowCount().should.eventually.have.at.least(1)
        .browserWindow.isVisible().should.eventually.be.true
        .browserWindow.getBounds().should.eventually.have.property('width').and.be.above(0)
        .browserWindow.getBounds().should.eventually.have.property('height').and.be.above(0)
        .element("#btn-minimize").click()
        .browserWindow.isVisible().should.eventually.be.false
    })

    it('maximizes', function () {
      return this.app.client.waitUntilWindowLoaded()
        .element("#btn-maximize").click()
        .browserWindow.isMaximized().should.eventually.be.true
    })

    it.skip('closes', function (done) {
      this.app.client.waitUntilWindowLoaded()
        .element("#btn-close").click()
      done()
      //.getWindowCount(count => Promise.resolve(count).should.eventually.equal(0))
      //.finally(done)
    })

  }, {
    close_after: true
  }))
}