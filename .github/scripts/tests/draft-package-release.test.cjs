const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { stageRelease } = require('../draft-package-release.cjs');

function fixture(t, existing = []) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'edhm-draft-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const env = { INSTALLER_VARIANT: 'free', GITHUB_REPOSITORY: 'Fenris159/EDHM_UI', GITHUB_SHA: 'a'.repeat(40) };
  fs.writeFileSync(path.join(directory, 'release-metadata.json'), JSON.stringify({ appVersion: '3.0.71', uiCommit: env.GITHUB_SHA, edhm: { version: 'v22.02' } }));
  for (const file of ['edhm-ui-v3-windows-x64.exe', 'edhm-ui-v3-linux-x64.zip', 'linux_installer.sh', 'release-notes.md']) fs.writeFileSync(path.join(directory, file), 'fixture');
  const calls = [];
  const gh = (...args) => {
    calls.push(args);
    if (args[0] === 'api') return JSON.stringify([existing]);
    if (args[1] === 'view') return JSON.stringify({ url: 'https://example.test/draft', isDraft: true });
    return '';
  };
  return { directory, env, gh, calls };
}

test('Staging uses draft/prerelease flags, exact app commit and generated notes file', t => {
  const f = fixture(t);
  stageRelease(f.directory, f.env, f.gh);
  const create = f.calls.find(args => args[1] === 'create');
  assert.ok(create.includes('--draft'));
  assert.ok(create.includes('--prerelease'));
  assert.equal(create[create.indexOf('--target') + 1], f.env.GITHUB_SHA);
  assert.equal(create[create.indexOf('--notes-file') + 1], path.join(f.directory, 'release-notes.md'));
  assert.equal(create[2], 'packaging-v3.0.71-free');
});

test('Published releases and other repositories cannot be modified', t => {
  const f = fixture(t, [{ tag_name: 'packaging-v3.0.71-free', draft: false }]);
  assert.throws(() => stageRelease(f.directory, f.env, f.gh), /published release/);
  assert.equal(f.calls.length, 1);
  assert.throws(() => stageRelease(f.directory, { ...f.env, GITHUB_REPOSITORY: 'BlueMystical/EDHM_UI' }, f.gh), /restricted to the fork/);
  assert.equal(f.calls.length, 1);
});

test('Missing assets and mismatched metadata fail before a release is created', t => {
  const f = fixture(t);
  assert.throws(() => stageRelease(f.directory, { ...f.env, GITHUB_SHA: 'b'.repeat(40) }, f.gh), /another app commit/);
  fs.unlinkSync(path.join(f.directory, 'edhm-ui-v3-windows-x64.exe'));
  assert.throws(() => stageRelease(f.directory, f.env, f.gh), /ENOENT/);
  assert.equal(f.calls.length, 0);
});

test('A newer commit replaces only its matching draft, while retries update the same draft', t => {
  const f = fixture(t, [{ tag_name: 'packaging-v3.0.71-free', draft: true, target_commitish: 'b'.repeat(40) }]);
  stageRelease(f.directory, f.env, f.gh);
  assert.deepEqual(f.calls.filter(args => args[0] === 'release').map(args => args[1]), ['delete', 'create', 'view']);
  const retry = fixture(t, [{ tag_name: 'packaging-v3.0.71-free', draft: true, target_commitish: f.env.GITHUB_SHA }]);
  stageRelease(retry.directory, retry.env, retry.gh);
  assert.deepEqual(retry.calls.filter(args => args[0] === 'release').map(args => args[1]), ['upload', 'edit', 'view']);
});
