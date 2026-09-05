const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

function stageRelease(directory, env = process.env, gh = (...args) => execFileSync('gh', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })) {
  directory = path.resolve(directory);
  const variant = env.INSTALLER_VARIANT;
  if (!['free', 'advanced-installer'].includes(variant)) throw new Error('Invalid installer variant');
  if (env.GITHUB_REPOSITORY !== 'Fenris159/EDHM_UI') throw new Error('Draft packaging tests are restricted to the fork');
  const metadata = JSON.parse(fs.readFileSync(path.join(directory, 'release-metadata.json'), 'utf8'));
  if (metadata.uiCommit !== env.GITHUB_SHA) throw new Error('Release metadata belongs to another app commit');
  const tag = `packaging-v${metadata.appVersion}-${variant}`;
  const title = `EDHM-UI v${metadata.appVersion} / EDHM ${metadata.edhm.version} (${variant} installer test)`;
  const assets = ['edhm-ui-v3-windows-x64.exe', 'edhm-ui-v3-linux-x64.zip', 'linux_installer.sh', 'release-metadata.json', 'release-notes.md']
    .map(name => path.join(directory, name));
  for (const file of assets) if (!fs.statSync(file).size) throw new Error(`Empty release asset: ${file}`);
  // Enumerate rather than treating any failed lookup (auth/network) as "not found".
  const pages = JSON.parse(gh('api', '--paginate', '--slurp', `repos/${env.GITHUB_REPOSITORY}/releases?per_page=100`));
  const existing = pages.flat().find(release => release.tag_name === tag);
  if (existing && !existing.draft) throw new Error('Refusing to overwrite a published release');
  if (existing && existing.target_commitish !== env.GITHUB_SHA) {
    // Do not leave old binaries visible with new notes if a replacement upload fails.
    gh('release', 'delete', tag, '--yes', '--repo', env.GITHUB_REPOSITORY);
  }
  if (!existing || existing.target_commitish !== env.GITHUB_SHA) {
    gh('release', 'create', tag, '--draft', '--prerelease', '--target', env.GITHUB_SHA,
      '--title', title, '--notes-file', path.join(directory, 'release-notes.md'), '--repo', env.GITHUB_REPOSITORY, ...assets);
  } else {
    gh('release', 'upload', tag, ...assets, '--clobber', '--repo', env.GITHUB_REPOSITORY);
    gh('release', 'edit', tag, '--draft', '--prerelease', '--title', title,
      '--notes-file', path.join(directory, 'release-notes.md'), '--repo', env.GITHUB_REPOSITORY);
  }
  const result = JSON.parse(gh('release', 'view', tag, '--json', 'url,isDraft', '--repo', env.GITHUB_REPOSITORY));
  if (!result.isDraft) throw new Error('Expected a draft test release');
  console.log(result.url);
  if (env.GITHUB_STEP_SUMMARY) fs.appendFileSync(env.GITHUB_STEP_SUMMARY, `\n[Draft ${variant} installer release](${result.url})\n`);
}
module.exports = { stageRelease };
if (require.main === module) stageRelease(process.argv[2]);
