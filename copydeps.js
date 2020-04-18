// copies engines, plugins, themes folders to dist folder

const asar = require("asar");
const nwFS = require("fs-extra");

nwFS.ensureDirSync("./dist/engines");
asar.createPackage("./engines/love2d/", "./dist/engines/love2d").then(e => {
  console.log(e);
});
