import fs from 'fs';
import path from 'path';

import { describe, expect, it } from 'vitest';
import { loadFront } from 'yaml-front-matter';

// Path to template configs relative to the project root
// The project is at: agent-forge/projects/aider-desk
// The configs are at: agent-forge/knowledge_base/aider-desk/configs
const CONFIGS_ROOT = path.resolve(__dirname, '../../../../../../knowledge_base/aider-desk/configs');

/** Recursively find files matching a pattern */
const findFiles = (dir: string, pattern: RegExp): string[] => {
  const results: string[] = [];
  if (!fs.existsSync(dir)) {
    return results;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findFiles(fullPath, pattern));
    } else if (pattern.test(entry.name)) {
      results.push(fullPath);
    }
  }
  return results;
};

/** Find all immediate children (files or dirs) in a directory */
const listDir = (dir: string): fs.Dirent[] => {
  if (!fs.existsSync(dir)) {
    return [];
  }
  return fs.readdirSync(dir, { withFileTypes: true });
};

/** Get all config variant directories (e.g., ror-agent-config, devops-agent-config) */
const getConfigDirs = (): string[] => {
  if (!fs.existsSync(CONFIGS_ROOT)) {
    return [];
  }
  return fs
    .readdirSync(CONFIGS_ROOT, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => path.join(CONFIGS_ROOT, d.name));
};

describe('Template Configuration Lint (Mitigation E)', () => {
  const configDirs = getConfigDirs();

  // E1: Agent template configs should not contain projectDir
  it('E1: agent template configs should not contain projectDir', () => {
    const agentConfigs = findFiles(CONFIGS_ROOT, /^config\.json$/);
    expect(agentConfigs.length).toBeGreaterThan(0);

    for (const configPath of agentConfigs) {
      const content = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
      expect(content).not.toHaveProperty('projectDir', `${path.relative(CONFIGS_ROOT, configPath)} contains projectDir`);
    }
  });

  // E2: Agent template configs should be valid JSON with id and name
  it('E2: agent template configs should be valid JSON with id and name', () => {
    const agentConfigs = findFiles(CONFIGS_ROOT, /^config\.json$/).filter((p) => !p.endsWith('order.json'));
    expect(agentConfigs.length).toBeGreaterThan(0);

    for (const configPath of agentConfigs) {
      const rel = path.relative(CONFIGS_ROOT, configPath);
      let content: Record<string, unknown>;
      try {
        content = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
      } catch (e) {
        throw new Error(`${rel} is not valid JSON: ${e}`);
      }
      expect(typeof content.id).toBe('string');
      expect((content.id as string).length).toBeGreaterThan(0);
      expect(typeof content.name).toBe('string');
      expect((content.name as string).length).toBeGreaterThan(0);
    }
  });

  // E3: Agent order.json files should be valid JSON
  it('E3: agent order.json files should be valid JSON', () => {
    const orderFiles = findFiles(CONFIGS_ROOT, /^order\.json$/);
    expect(orderFiles.length).toBeGreaterThan(0);

    for (const orderPath of orderFiles) {
      const rel = path.relative(CONFIGS_ROOT, orderPath);
      let content: Record<string, unknown>;
      try {
        content = JSON.parse(fs.readFileSync(orderPath, 'utf-8'));
      } catch (e) {
        throw new Error(`${rel} is not valid JSON: ${e}`);
      }

      // All values should be numbers
      for (const [_key, value] of Object.entries(content)) {
        expect(typeof value).toBe('number');
      }
    }
  });

  // E4: Agent order.json should reference only existing agent dirs
  it('E4: agent order.json should reference only existing agent dirs', () => {
    const orderFiles = findFiles(CONFIGS_ROOT, /^order\.json$/);

    for (const orderPath of orderFiles) {
      const agentsDir = path.dirname(orderPath);
      const content = JSON.parse(fs.readFileSync(orderPath, 'utf-8'));
      const siblingDirs = listDir(agentsDir)
        .filter((d) => d.isDirectory())
        .map((d) => d.name);

      for (const key of Object.keys(content)) {
        expect(siblingDirs).toContain(key);
      }
    }
  });

  // E5: Skill templates should use correct directory structure
  it('E5: skill templates should use correct directory structure', () => {
    for (const configDir of configDirs) {
      const skillsDir = path.join(configDir, 'skills');
      if (!fs.existsSync(skillsDir)) {
        continue;
      }

      const entries = listDir(skillsDir);
      for (const entry of entries) {
        const fullPath = path.join(skillsDir, entry.name);

        // Each entry in skills/ must be a directory, not a flat .md file
        expect(entry.isDirectory()).toBe(true);

        // The directory must contain SKILL.md
        const skillMdPath = path.join(fullPath, 'SKILL.md');
        expect(fs.existsSync(skillMdPath)).toBe(true);
      }
    }
  });

  // E6: Skill templates should have valid frontmatter with name and description
  it('E6: skill templates should have valid frontmatter with name and description', () => {
    const skillFiles = findFiles(CONFIGS_ROOT, /^SKILL\.md$/);
    expect(skillFiles.length).toBeGreaterThan(0);

    for (const skillPath of skillFiles) {
      const content = fs.readFileSync(skillPath, 'utf-8');
      const parsed = loadFront(content);

      expect(typeof parsed.name).toBe('string');
      expect((parsed.name as string).trim().length).toBeGreaterThan(0);
      expect(typeof parsed.description).toBe('string');
      expect((parsed.description as string).trim().length).toBeGreaterThan(0);
    }
  });

  // E7: Command templates should have valid frontmatter with description
  it('E7: command templates should have valid frontmatter with description', () => {
    const commandFiles: string[] = [];
    for (const configDir of configDirs) {
      const commandsDir = path.join(configDir, 'commands');
      if (!fs.existsSync(commandsDir)) {
        continue;
      }
      const mdFiles = findFiles(commandsDir, /\.md$/);
      commandFiles.push(...mdFiles);
    }

    expect(commandFiles.length).toBeGreaterThan(0);

    for (const cmdPath of commandFiles) {
      const content = fs.readFileSync(cmdPath, 'utf-8');
      const parsed = loadFront(content);

      expect(typeof parsed.description).toBe('string');
      expect((parsed.description as string).trim().length).toBeGreaterThan(0);
    }
  });

  // E8: No template should contain absolute paths
  it('E8: no template should contain absolute paths', () => {
    const allFiles = findFiles(CONFIGS_ROOT, /\.(json|md)$/);
    const absPathPattern = /\/home\/|\/Users\/|C:\\/;

    for (const filePath of allFiles) {
      const content = fs.readFileSync(filePath, 'utf-8');
      expect(absPathPattern.test(content)).toBe(false);
    }
  });
});
