'use strict';
class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
function validateMessages(messages) {
  if (!Array.isArray(messages) || messages.length < 1 || messages.length > 32) {
    throw new ApiError(400, 'Invalid conversation');
  }
  let total = 0;
  return messages.map(message => {
    if (!message || !['user', 'assistant', 'system'].includes(message.role) ||
        typeof message.content !== 'string' || !message.content.trim() ||
        message.content.length > 8000) throw new ApiError(400, 'Invalid message');
    total += message.content.length;
    if (total > 24000) throw new ApiError(400, 'Conversation too long');
    // Client system prompts contain goal context, never override server policy.
    return {role: message.role === 'system' ? 'user' : message.role, content: message.content};
  });
}
function requireRecentLogin(token, now = Date.now()) {
  const age = Math.floor(now / 1000) - token.auth_time;
  if (!Number.isFinite(age) || age < 0 || age > 300) {
    throw new ApiError(409, 'Recent sign-in required');
  }
}
function validateReport(body) {
  if (typeof body.content !== 'string' || !body.content.trim() || body.content.length > 16000 ||
      typeof body.reason !== 'string' || !body.reason.trim() || body.reason.length > 1000) {
    throw new ApiError(400, 'Invalid report');
  }
  return {content: body.content, reason: body.reason};
}
module.exports = {ApiError, validateMessages, requireRecentLogin, validateReport};
