const zip = require('archiver')
const fs = require('fs-extra')

fs.removeSync(__dirname+"/dist/BlankE.zip")
var output = fs.createWriteStream(__dirname+'/dist/BlankE.zip')
var archive = zip('zip',{ zlib: {level:9}})
output.on('end',() => {

})
archive.pipe(output)
archive.directory(__dirname+'/dist/BlankE-win32-x64/', false)
archive.finalize()