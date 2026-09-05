const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const appRoot = path.resolve(__dirname, '../../source_v3');
const asar = require(path.join(appRoot, 'node_modules/@electron/asar'));
const name = process.platform === 'win32' ? 'EDHM-UI-V3-win32-x64' : 'edhm-ui-v3-linux-x64';
const archive = path.join(appRoot, 'out', name, 'resources/app.asar');
const pkg = JSON.parse(asar.extractFile(archive, 'package.json'));
const main = asar.extractFile(archive, path.normalize(pkg.main)).toString();
assert.ok(main.indexOf('VelopackApp.build().run()') >= 0, 'Missing installer bootstrap');
assert.ok(main.indexOf('VelopackApp.build().run()') < main.indexOf('require("electron")'), 'Installer hook must precede Electron imports');
for (const dependency of Object.keys(pkg.dependencies)) {
  assert.ok(asar.statFile(archive, path.join('node_modules', dependency, 'package.json')), `Missing external dependency: ${dependency}`);
}
if (process.platform === 'win32') {
  assert.ok(fs.existsSync(`${archive}.unpacked/node_modules/velopack/lib/native/velopack_nodeffi_win_x64_msvc.node`), 'Native SDK must be unpacked');
}
console.log(`Packaged ${name} includes its bootstrap and all external dependencies.`);
