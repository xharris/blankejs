const http = require('request');
const fs = require('fs-extra');
const zip = require('adm-zip')

fs.removeSync('./butler')
fs.removeSync('./butler.zip')
const file = fs.createWriteStream("./butler.zip");
const request = http({
    followAllRedirects: true,
    url: "https://broth.itch.ovh/butler/windows-amd64/LATEST/archive/default"
})
request.pipe(file)
request.on('end',()=>{
    fs.mkdirSync('./butler')
    zip('./butler.zip').extractAllTo('./butler', true);
    fs.removeSync('./butler.zip')
})