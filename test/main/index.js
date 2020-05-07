module.exports = function (helper) {
  require('./application')(helper)
  require('./project')(helper)
};