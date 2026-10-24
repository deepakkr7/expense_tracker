const {Timestamp} = require('firebase-admin/firestore');

async function eraseAccount(db, auth, uid) {
  await db.recursiveDelete(db.doc(`expense_tracker/users/users/${uid}`));
  await db.recursiveDelete(db.doc(`service_usage/${uid}`));
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    // Retry safely if Auth deletion succeeded before a previous request failed.
    if (error.code !== 'auth/user-not-found') throw error;
  }
  try {
    await db.doc(`account_lifecycle/${uid}`).set({
      state: 'complete', deleting: true,
      expiresAt: Timestamp.fromMillis(Date.now() + 86400000),
    });
  } catch (_) {
    // A pending marker remains locked and the scheduled worker retries it.
    console.error('Completed deletion marker needs repair');
  }
}
module.exports = {eraseAccount};
