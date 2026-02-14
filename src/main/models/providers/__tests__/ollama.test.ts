import { describe, expect, it } from 'vitest';
import { OllamaProvider } from '@common/agent';
import { ProviderProfile } from '@common/types';

import { getOllamaAiderMapping } from '@/models/providers/ollama';

describe('getOllamaAiderMapping', () => {
  it('uses the ollama provider prefix and normalizes the base URL', () => {
    const provider: ProviderProfile = {
      id: 'ollama-profile',
      provider: {
        name: 'ollama',
        baseUrl: 'http://localhost:11434/api',
      } satisfies OllamaProvider,
    };

    const mapping = getOllamaAiderMapping(provider, 'qwen3-coder-next:latest');

    expect(mapping.modelName).toBe('ollama/qwen3-coder-next:latest');
    expect(mapping.environmentVariables).toEqual({
      OLLAMA_API_BASE: 'http://localhost:11434',
    });
  });
});
