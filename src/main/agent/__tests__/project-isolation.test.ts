import path from 'path';
import * as fs from 'fs/promises';

import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AgentProfileManager } from '../agent-profile-manager';

vi.mock('@/logger', () => ({
  default: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
  },
}));
vi.mock('@/events');
vi.mock('@/constants');
vi.mock('@/utils', () => ({
  deriveDirName: vi.fn((name: string) => name.toLowerCase().replace(/\s+/g, '-')),
  fileExists: vi.fn().mockResolvedValue(true),
}));
vi.mock('path', async () => {
  const actual = (await vi.importActual('path')) as any;
  return {
    ...actual,
    join: vi.fn((...args) => args.join('/')),
    basename: actual.basename,
    dirname: actual.dirname,
  };
});
vi.mock('fs/promises');

describe('AgentProfileManager Project Isolation', () => {
  let agentProfileManager: AgentProfileManager;
  let mockEventManager: any;

  beforeEach(async () => {
    vi.clearAllMocks();
    mockEventManager = {
      sendAgentProfilesUpdated: vi.fn(),
    };
    (fs.access as any).mockResolvedValue(undefined);
    (fs.mkdir as any).mockResolvedValue(undefined);
    (fs.readFile as any).mockImplementation(async (filePath: string) => {
      if (filePath.includes('config.json')) {
        // Return a basic config based on the directory name
        const id = path.basename(path.dirname(filePath));
        return JSON.stringify({ id, name: id });
      }
      return '{}';
    });
    agentProfileManager = new AgentProfileManager(mockEventManager);
  });

  it('should allow agents with the same ID in different projects', async () => {
    const project1Dir = '/projects/project1';
    const project2Dir = '/projects/project2';
    const agentId = 'shared-agent';

    (fs.readdir as any).mockImplementation(async (dirPath: string) => {
      if (dirPath.includes('project1') || dirPath.includes('project2')) {
        return [{ name: agentId, isDirectory: () => true, isSymbolicLink: () => false }];
      }
      return [];
    });

    // Mock loadProfileFile to return a valid profile
    (agentProfileManager as any).loadProfileFile = vi.fn().mockImplementation(async (_configPath: string, dirName: string) => {
      return { id: dirName, name: dirName };
    });

    // Initialize both projects
    await agentProfileManager.initializeForProject(project1Dir);
    await agentProfileManager.initializeForProject(project2Dir);

    const allProfiles = agentProfileManager.getAllProfiles();

    // We expect 2 profiles even though they share the same ID
    expect(allProfiles).toHaveLength(2);

    const p1Agent = agentProfileManager.getProfile(agentId, project1Dir);
    const p2Agent = agentProfileManager.getProfile(agentId, project2Dir);

    expect(p1Agent).toBeDefined();
    expect(p2Agent).toBeDefined();
    expect(p1Agent?.projectDir).toBe(project1Dir);
    expect(p2Agent?.projectDir).toBe(project2Dir);
  });

  it('should prioritize project agent over global agent with same ID', async () => {
    const projectDir = '/projects/project-a';
    const agentId = 'agent-x';

    // Mock profilesMap in profiles manually to simulate global and project agents
    const globalProfile = { id: agentId, name: 'Global Version' };
    const projectProfile = { id: agentId, name: 'Project Version', projectDir };

    (agentProfileManager as any).profiles.set('global#' + agentId, {
      dirName: agentId,
      order: 0,
      agentProfile: globalProfile,
    });
    (agentProfileManager as any).profiles.set(projectDir + '#' + agentId, {
      dirName: agentId,
      order: 0,
      agentProfile: projectProfile,
    });

    const resolvedProfile = agentProfileManager.getProfile(agentId, projectDir);
    expect(resolvedProfile?.name).toBe('Project Version');

    const globalResolved = agentProfileManager.getProfile(agentId);
    expect(globalResolved?.name).toBe('Global Version');
  });

  it('should not return duplicate agent IDs in getProjectProfiles', async () => {
    const projectDir = '/projects/project1';
    const agentId = 'shared-agent';

    const globalProfile = { id: agentId, name: 'Global Version' };
    const projectProfile = { id: agentId, name: 'Project Version', projectDir };

    (agentProfileManager as any).profiles.set('global#' + agentId, {
      dirName: agentId,
      order: 0,
      agentProfile: globalProfile,
    });
    (agentProfileManager as any).profiles.set(projectDir + '#' + agentId, {
      dirName: agentId,
      order: 0,
      agentProfile: projectProfile,
    });

    const profiles = agentProfileManager.getProjectProfiles(projectDir);

    // Check for duplicates
    const counts = profiles.reduce((acc, p) => {
      acc[p.id] = (acc[p.id] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    expect(counts[agentId]).toBe(1);

    // Ensure we got the project version
    const profile = profiles.find((p) => p.id === agentId);
    expect(profile?.name).toBe('Project Version');
    expect(profile?.projectDir).toBe(projectDir);
  });
});
