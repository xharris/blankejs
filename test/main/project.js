module.exports = function (helper) {
  const { name, setup } = helper;

  describe.skip(name('Application', 'Project'), setup(function () {
    it('creates new project', function () {
      return this.app.client.waitUntilWindowLoaded()
        .element("#search-input").text("new project")
        .element("")
    })
  }))
}