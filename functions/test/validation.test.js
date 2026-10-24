const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateMessages, requireRecentLogin, validateReport} = require('../validation');

test('reject malformed, oversized and unbounded paid AI requests', () => {
  for (const messages of [null, [], [{role:'tool', content:'x'}],
    [{role:'user', content:'x'.repeat(8001)}], Array(33).fill({role:'user',content:'x'}),
    Array(4).fill({role:'user',content:'x'.repeat(8000)})]) {
    assert.throws(() => validateMessages(messages), {status:400});
  }
});
test('client system context cannot become a server system instruction', () => {
  assert.deepEqual(validateMessages([{role:'system',content:'Goal context'}]),
    [{role:'user',content:'Goal context'}]);
});
test('account deletion requires recent authentication, not a fresh token refresh', () => {
  const now = 1000000;
  requireRecentLogin({auth_time:700}, now);
  for (const auth_time of [699, 1001, undefined, NaN]) {
    assert.throws(() => requireRecentLogin({auth_time}, now), {status:409});
  }
});
test('reports must contain bounded response and reason', () => {
  assert.deepEqual(validateReport({content:'Response',reason:'Unsafe'}), {content:'Response',reason:'Unsafe'});
  assert.throws(() => validateReport({content:'Response',reason:''}), {status:400});
  assert.throws(() => validateReport({content:'x'.repeat(16001),reason:'Unsafe'}), {status:400});
});
