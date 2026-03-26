#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');
const os = require('os');

const REPO = 'Fldicoahkiin/code-alchemist';

function getGlobalSkillsDir() {
  return path.join(os.homedir(), '.claude', 'skills');
}

function findProjectRoot() {
  let current = process.cwd();
  while (current !== '/') {
    if (fs.existsSync(path.join(current, '.git')) ||
        fs.existsSync(path.join(current, 'package.json'))) {
      return current;
    }
    current = path.dirname(current);
  }
  return null;
}

function parseArgs() {
  const args = process.argv.slice(2);
  return {
    help: args.includes('--help') || args.includes('-h'),
    update: args.includes('--update') || args.includes('-u')
  };
}

function showHelp() {
  console.log(`
CodeAlchemist Installer

Usage: npx code-alchemist [options]

Options:
  -u, --update    Update existing installation
  -h, --help      Show this help message

Interactive installation will ask for:
  - Install location (current project / global)
  - Install method (copy / symlink)
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

  try {
    const projectRoot = findProjectRoot();
    const globalDir = getGlobalSkillsDir();

    console.log('\n=== CodeAlchemist Installation ===\n');

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
        break;
      }
      console.log('Invalid choice, please enter 1 or 2');
    }

    const installDir = locationChoice === '1' ? projectInstallDir : globalInstallDir;
    const exists = locationChoice === '1' ? projectExists : globalExists;

    if (exists && !isUpdate) {
      const answer = await askQuestion(rl, '\nCodeAlchemist already installed here. Update? (y/n): ');
      if (answer.toLowerCase() !== 'y') {
        console.log('Installation cancelled.');
        return;
      }
    }

    console.log('\nSelect install method:');
    console.log('  1) Copy (recommended)');
    console.log('  2) Symlink (for development)');

    let methodChoice;
    while (true) {
      const answer = await askQuestion(rl, '\nEnter choice (1 or 2): ');
      if (answer === '1' || answer === '2') {
        methodChoice = answer;
        break;
      }
      console.log('Invalid choice, please enter 1 or 2');
    }

    rl.close();

    await performInstall(installDir, methodChoice === '2', isUpdate || exists);

  } catch (err) {
    rl.close();
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

function performInstall(installDir, isSymlink, isUpdate) {
  console.log(`\n${isUpdate ? 'Updating' : 'Installing'} CodeAlchemist...`);
  console.log(`Location: ${installDir}`);
  console.log(`Method: ${isSymlink ? 'Symlink' : 'Copy'}\n`);

  if (fs.existsSync(installDir)) {
    fs.rmSync(installDir, { recursive: true, force: true });
  }

  fs.mkdirSync(installDir, { recursive: true });

  const files = [
    'SKILL.md',
    'evals/evals.json',
    'scripts/distill_author.sh',
    'scripts/validate_skill.sh',
    'references/distillation-dimensions.md',
    'references/output-contract.md',
    'templates/skill-template.md',
    'templates/agents-snippet.md'
  ];

  let successCount = 0;

  for (const file of files) {
    const url = `https://raw.githubusercontent.com/${REPO}/main/.agents/skills/code-alchemist/${file}`;
    const localPath = path.join(installDir, file);
    fs.mkdirSync(path.dirname(localPath), { recursive: true });

    if (downloadWithRetry(url, localPath)) {
      console.log(`  [OK] ${file}`);
      successCount++;
    } else {
      console.log(`  [ERROR] ${file} (download failed after ${MAX_RETRIES} attempts)`);
    }
  }

  const distillScript = path.join(installDir, 'scripts', 'distill_author.sh');
  const validateScript = path.join(installDir, 'scripts', 'validate_skill.sh');
  if (fs.existsSync(distillScript)) {
    fs.chmodSync(distillScript, 0o755);
  }
  if (fs.existsSync(validateScript)) {
    fs.chmodSync(validateScript, 0o755);
  }

  console.log(`\n[OK] ${isUpdate ? 'Update' : 'Installation'} complete!`);
  console.log(`  Files installed: ${successCount}/${files.length}`);
  console.log(`  Location: ${installDir}\n`);
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
