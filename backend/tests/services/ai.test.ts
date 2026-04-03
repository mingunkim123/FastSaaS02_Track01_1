import { beforeEach, describe, expect, it, vi } from 'vitest';

const getGenerativeModelMock = vi.fn();

vi.mock('@google/generative-ai', () => ({
  GoogleGenerativeAI: class MockGoogleGenerativeAI {
    getGenerativeModel = getGenerativeModelMock;
  },
}));

import { AIService, AIServiceError } from '../../src/services/ai';

describe('AIService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('parses JSON wrapped in markdown code fences', async () => {
    getGenerativeModelMock.mockReturnValue({
      generateContent: vi.fn().mockResolvedValue({
        response: {
          text: () => '```json\n{"type":"read","payload":{"month":"2024-03"},"confidence":0.95}\n```',
        },
      }),
    });

    const service = new AIService('test-api-key');
    const result = await service.parseUserInput('3월 내역 보여줘', [], []);

    expect(result.type).toBe('read');
    expect(result.payload).toEqual({ month: '2024-03' });
    expect(getGenerativeModelMock).toHaveBeenCalledWith({ model: 'gemini-2.0-flash' });
  });

  it('falls back to the secondary model when the primary model fails', async () => {
    getGenerativeModelMock
      .mockReturnValueOnce({
        generateContent: vi.fn().mockRejectedValue(new Error('primary model unavailable')),
      })
      .mockReturnValueOnce({
        generateContent: vi.fn().mockResolvedValue({
          response: {
            text: () => '{"type":"create","payload":{"transactionType":"expense","amount":12000,"category":"food","date":"2024-03-15"},"confidence":0.9}',
          },
        }),
      });

    const service = new AIService('test-api-key');
    const result = await service.parseUserInput('점심 12000원 썼어', [], []);

    expect(result.type).toBe('create');
    expect(getGenerativeModelMock).toHaveBeenNthCalledWith(1, { model: 'gemini-2.0-flash' });
    expect(getGenerativeModelMock).toHaveBeenNthCalledWith(2, { model: 'gemini-1.5-flash' });
  });

  it('throws AIServiceError after all models fail', async () => {
    getGenerativeModelMock.mockReturnValue({
      generateContent: vi.fn().mockRejectedValue(new Error('model unavailable')),
    });

    const service = new AIService('test-api-key');

    await expect(service.parseUserInput('테스트', [], [])).rejects.toBeInstanceOf(AIServiceError);
  });
});
