#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const REPO = 'Fldicoahkiin/code-alchemist';
const DEFAULT_VERSION = 'v1.1.0'; // Fallback version

function getVersion() {
  // Check for fallback flag (set when version download fails)
  if (process.env.CODE_ALCHEMIST_FALLBACK === 'true') {
    return 'main';
  }
  // Try to get version from npm environment (when installed via npm)
  const npmPackageVersion = process.env.npm_package_version;
  if (npmPackageVersion) {
    return `v${npmPackageVersion}`;
  }
  // Fallback to default
  return DEFAULT_VERSION;
}

function findProjectRoot() {
  let dir = process.cwd();
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, '.git')) || fs.existsSync(path.join(dir, 'package.json'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  return null;
}

function getGlobalSkillsDir() {
  const homeDir = process.env.HOME || process.env.USERPROFILE;
  return path.join(homeDir, '.claude', 'skills');
}

function parseArgs() {
  const args = process.argv.slice(2);
  const options = { help: false, update: false };
  for (const arg of args) {
    if (arg === '--help' || arg === '-h') options.help = true;
    if (arg === '--update' || arg === '-u') options.update = true;
  }
  return options;
}

function showHelp() {
  console.log(`
Code Alchemist Installer

Usage: npx code-alchemist [options]

Options:
  -h, --help     Show help
  -u, --update   Update existing installation

Note: The recommended install method is:
  npx skills add Fldicoahkiin/code-alchemist
`);
}

function askQuestion(rl, question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer.trim()));
  });
}

async function interactiveInstall(isUpdate) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  let rlClosed = false;
  const safeClose = () => {
    if (!rlClosed) {
      rl.close();
      rlClosed = true;
    }
  };

  try {
    const projectRoot = findProjectRoot();
    const globalDir = getGlobalSkillsDir();

    console.log('\n=== Code Alchemist Installation ===\n');

    const projectInstallDir = projectRoot ? path.join(projectRoot, '.agents', 'skills', 'code-alchemist') : null;
    const globalInstallDir = path.join(globalDir, 'code-alchemist');

    const projectExists = projectInstallDir && fs.existsSync(projectInstallDir);
    const globalExists = fs.existsSync(globalInstallDir);

    if (isUpdate) {
      console.log('Update mode - checking existing installations...\n');
    }

    console.log('Select install location:');
    if (projectRoot) {
      console.log(`  1) Current project (${projectRoot})`);
    } else {
      console.log('  1) Current project (not found - no .git or package.json)');
    }
    console.log(`  2) Global (~/.claude/skills/)`);

    let locationChoice;
    while (true) {
      const answer = await askQuestion(rl, '\nEnter choice (1 or 2): ');
      if (answer === '1' || answer === '2') {
        locationChoice = answer;
        if (locationChoice === '1' && !projectRoot) {
            console.log('Error: Project root not found (.git or package.json missing). Please install inside a valid project or select Global.');
            continue;
        }
        break;
      }
      console.log('Invalid choice, please enter 1 or 2');
    }

    const installDir = locationChoice === '1' ? projectInstallDir : globalInstallDir;
    const exists = locationChoice === '1' ? projectExists : globalExists;

    if (exists && !isUpdate) {
      const answer = await askQuestion(rl, '\nCode Alchemist already installed here. Update? (y/n): ');
      if (answer.toLowerCase() !== 'y') {
        console.log('Installation cancelled.');
        safeClose();
        return;
      }
    }

    safeClose();

    await performInstall(installDir, isUpdate || exists);

  } catch (err) {
    safeClose();
    throw err;
  }
}

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 2000;

function downloadWithRetry(url, localPath, maxRetries = MAX_RETRIES) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      execSync(`curl -fsSL --connect-timeout 10 --max-time 30 "${url}" -o "${localPath}" 2>/dev/null`);
      return true;
    } catch (e) {
      if (attempt < maxRetries) {
        execSync(`sleep ${RETRY_DELAY_MS / 1000}`);
      }
    }
  }
  return false;
}

function performInstall(installDir, isUpdate) {
  console.log(`\n${isUpdate ? 'Updating' : 'Installing'} Code Alchemist...`);
  console.log(`Location: ${installDir}\n`);

  const os = require('os');
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'code-alchemist-'));

  const files = [
    'SKILL.md',
    'skill.lock.json',
    'evals/evals.json',
    'scripts/distill_author.sh',
    'scripts/validate_skill.sh',
    'references/distillation-dimensions.md',
    'references/output-contract.md',
    'templates/skill-template.md',
    'templates/agents-snippet.md',
    'agents/openai.yaml'
  ];

  let successCount = 0;

  for (const file of files) {
    const version = getVersion();
    const url = `https://raw.githubusercontent.com/${REPO}/${version}/.agents/skills/code-alchemist/${file}`;
    const localPath = path.join(tempDir, file);
    fs.mkdirSync(path.dirname(localPath), { recursive: true });

    if (downloadWithRetry(url, localPath)) {
      console.log(`  [OK] ${file}`);
      successCount++;
    } else {
      console.log(`  [ERROR] ${file} (download failed after ${MAX_RETRIES} attempts)`);
      console.log(`          URL: ${url}`);

      // Try fallback to main branch for current file and subsequent files
      if (version !== 'main') {
        console.log(`  [HINT] Version ${version} may not exist yet. Falling back to 'main' branch.`);
        process.env.CODE_ALCHEMIST_FALLBACK = 'true';

        const fallbackUrl = `https://raw.githubusercontent.com/${REPO}/main/.agents/skills/code-alchemist/${file}`;
        if (downloadWithRetry(fallbackUrl, localPath)) {
          console.log(`  [OK] ${file} (fallback to main)`);
          successCount++;
        } else {
          console.log(`  [ERROR] ${file} (fallback failed)`);
        }
      }
    }
  }

  if (successCount === files.length) {
    // Set executable permission on shell scripts
    const scriptDir = path.join(tempDir, 'scripts');
    if (fs.existsSync(scriptDir)) {
      fs.readdirSync(scriptDir).forEach(file => {
        if (file.endsWith('.sh')) {
          fs.chmodSync(path.join(scriptDir, file), 0o755);
        }
      });
    }

    if (fs.existsSync(installDir)) {
      fs.rmSync(installDir, { recursive: true, force: true });
    }
    fs.mkdirSync(installDir, { recursive: true });

    function copyDirSync(src, dest) {
      fs.mkdirSync(dest, { recursive: true });
      for (const entry of fs.readdirSync(src)) {
        const srcPath = path.join(src, entry);
        const destPath = path.join(dest, entry);
        if (fs.statSync(srcPath).isDirectory()) {
          copyDirSync(srcPath, destPath);
        } else {
          fs.copyFileSync(srcPath, destPath);
        }
      }
    }
    
    copyDirSync(tempDir, installDir);
    fs.rmSync(tempDir, { recursive: true, force: true });

    console.log(`\n[OK] ${isUpdate ? 'Update' : 'Installation'} complete!`);
  } else {
    fs.rmSync(tempDir, { recursive: true, force: true });
    console.log(`\n[ERROR] ${isUpdate ? 'Update' : 'Installation'} incomplete: ${files.length - successCount} file(s) failed.`);
  }
  console.log(`  Files installed: ${successCount}/${files.length}`);
  console.log(`  Location: ${installDir}\n`);

  if (successCount < files.length) {
    process.exit(1);
  }

  console.log('Usage in Claude Code:');
  console.log('  把 <author> 炼成 skill');
  console.log('');
}

function main() {
  const args = parseArgs();

  if (args.help) {
    showHelp();
    return;
  }

  interactiveInstall(args.update).catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });
}

main();
