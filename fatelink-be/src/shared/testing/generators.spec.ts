import { spawnSync } from 'node:child_process';
import path from 'node:path';

describe('Scaffold generators', () => {
  it('prints HTTP generator help successfully', () => {
    const script = path.resolve(__dirname, '../../../tools/gen-http-api.mjs');
    const result = spawnSync(process.execPath, [script, '--help'], {
      encoding: 'utf8',
    });

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('gen:http-api');
  });

  it('prints WebSocket generator help successfully', () => {
    const script = path.resolve(__dirname, '../../../tools/gen-ws-api.mjs');
    const result = spawnSync(process.execPath, [script, '--help'], {
      encoding: 'utf8',
    });

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('gen:ws-api');
  });
});
