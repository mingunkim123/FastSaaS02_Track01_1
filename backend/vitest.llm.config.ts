// NOTE: @cloudflare/vitest-pool-workers requires Vitest ≤ 2.x.
// This project uses Vitest 4.x (currently ^4.1.2), so the Workers pool cannot be used.
// LLM smoke tests are written to use mocked callLLM with structural assertions.
// To run real LLM calls against the Workers runtime, either:
//   (a) downgrade vitest to ^2.x and use defineWorkersConfig, or
//   (b) run `wrangler dev` and exercise the endpoints via curl / an external test runner.

import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include:
      process.env.RUN_LLM_TESTS === '1'
        ? ['tests/llm-smoke/**/*.llm.test.ts']
        : [],
    setupFiles: ['./tests/setup-env.ts'],
  },
});
