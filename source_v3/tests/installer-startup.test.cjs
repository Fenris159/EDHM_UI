const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

test('Windows installer hooks run before any application import and may terminate startup', async () => {
  const { installerStartup } = await import('../vite.main.config.mjs');
  const calls = [];
  const hookExit = new Error('installer hook exited');
  assert.throws(() => vm.runInNewContext(`${installerStartup}\nrequire('electron');`, {
    process: { platform: 'win32' },
    require(name) {
      calls.push(name);
      return { VelopackApp: { build: () => ({ run() { throw hookExit; } }) } };
    },
  }), error => error === hookExit);
  assert.deepEqual(calls, ['velopack']);
});

test('Normal Windows startup continues after the hook; Linux does not load the Windows installer SDK', async () => {
  const { installerStartup } = await import('../vite.main.config.mjs');
  for (const platform of ['win32', 'linux']) {
    const calls = [];
    vm.runInNewContext(`${installerStartup}\nrequire('electron');`, {
      process: { platform },
      require(name) {
        calls.push(name);
        return { VelopackApp: { build: () => ({ run() { calls.push('run'); } }) } };
      },
    });
    assert.deepEqual(calls, platform === 'win32' ? ['velopack', 'run', 'electron'] : ['electron']);
  }
});

test('Custom Windows shortcut follows the actual installed executable and redirected desktop', () => {
  const source = fs.readFileSync(path.join(__dirname, '../src/Helpers/FileHelper.js'), 'utf8');
  const code = source.slice(source.indexOf('function createWindowsShortcut('), source.indexOf('function createLinuxShortcut('));
  const exe = "C:\\Users\\O'Brien Ω\\AppData\\Local\\Example.App\\current\\EDHM-UI-V3.exe";
  const desktop = "C:\\Users\\O'Brien Ω\\OneDrive\\Desktop";
  let written;
  vm.runInNewContext(`${code}\ncreateWindowsShortcut('D:\\icon.ico');`, {
    path: path.win32, console,
    app: { getPath: name => name === 'exe' ? exe : desktop },
    shell: { writeShortcutLink(...args) { written = args; return true; } },
  });
  assert.equal(written[0], path.win32.join(desktop, 'EDHM-UI-V3.lnk'));
  assert.equal(written[1], 'create');
  assert.equal(written[2].target, exe);
  assert.equal(written[2].cwd, path.win32.dirname(exe));
});
