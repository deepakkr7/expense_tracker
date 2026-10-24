const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
const {eraseAccount} = require('../deletion');
let app, db, auth;
const endpoint = 'http://127.0.0.1:5101/demo-spendwise/asia-south1/spendwiseApi';
before(() => {
  assert.equal(process.env.GCLOUD_PROJECT, 'demo-spendwise');
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST);
  app = initializeApp({projectId:'demo-spendwise'});
  db = getFirestore(app);
  auth = getAuth(app);
});
after(async () => { if (app) await deleteApp(app); });
async function signup(email) {
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
    method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({email,password:'emulator-only-password',returnSecureToken:true}),
  });
  assert.equal(response.status,200);
  return response.json();
}
async function call(token, body) {
  const response = await fetch(endpoint, {method:'POST',
    headers:{'Content-Type':'application/json',...(token ? {Authorization:`Bearer ${token}`} : {})},
    body:JSON.stringify(body),
  });
  return {status:response.status, body:await response.json()};
}
test('API authenticates, bounds paid requests, records reports, and recursively deletes only caller data', async () => {
  assert.equal((await call(null,{action:'ai'})).status,401);
  assert.equal((await call('invalid-token',{action:'deleteAccount'})).status,401);
  const alice = await signup('api-alice@example.test');
  const bob = await signup('api-bob@example.test');
  const alicePath = `expense_tracker/users/users/${alice.localId}`;
  const bobPath = `expense_tracker/users/users/${bob.localId}`;
  await db.doc(alicePath).set({id:alice.localId,name:'Alice'});
  await db.doc(bobPath).set({id:bob.localId,name:'Bob'});
  await db.doc(`${alicePath}/expenses/one`).set({amount:12});
  await db.doc(`${alicePath}/savings_goals/one/deposits/nested`).set({amount:3});
  assert.equal((await call(alice.idToken,{action:'findFriend',email:'api-bob@example.test'})).status,403);
  assert.equal((await call(alice.idToken,{action:'ai',messages:[]})).status,400);
  await db.doc(`service_usage/${alice.localId}/actions/ai`).set({day:new Date().toISOString().slice(0,10),count:50});
  assert.equal((await call(alice.idToken,{action:'ai',messages:[{role:'user',content:'Budget please'}]})).status,429);
  assert.equal((await call(alice.idToken,{action:'reportAi',content:'Unsafe response',reason:'Unsafe'})).status,200);
  assert.equal((await db.collection(`${alicePath}/ai_reports`).get()).size,1);
  assert.equal((await call(alice.idToken,{action:'reportAi',content:'Unsafe response',reason:''})).status,400);
  // A malicious body UID cannot select somebody else's account for deletion.
  const deleted = await call(alice.idToken,{action:'deleteAccount',uid:bob.localId});
  assert.equal(deleted.status,200);
  assert.equal(deleted.body.deleted,true);
  assert.equal((await db.doc(alicePath).get()).exists,false);
  assert.equal((await db.doc(`${alicePath}/expenses/one`).get()).exists,false);
  assert.equal((await db.doc(`${alicePath}/savings_goals/one/deposits/nested`).get()).exists,false);
  assert.equal((await db.collection(`${alicePath}/ai_reports`).get()).size,0);
  assert.equal((await db.doc(`service_usage/${alice.localId}/actions/ai`).get()).exists,false);
  assert.equal((await db.doc(bobPath).get()).exists,true);
  await assert.rejects(auth.getUser(alice.localId),{code:'auth/user-not-found'});
  assert.equal((await auth.getUser(bob.localId)).uid,bob.localId);
  assert.ok((await db.doc(`account_lifecycle/${alice.localId}`).get()).data().expiresAt);
  assert.equal((await call(alice.idToken,{action:'reportAi',content:'Old token',reason:'test'})).status,401);
  // Recover from an interrupted deletion whose Auth account is already gone.
  await db.doc('account_lifecycle/interrupted-deletion').set({state:'pending',deleting:true});
  await db.doc('expense_tracker/users/users/interrupted-deletion/expenses/leftover').set({amount:1});
  await eraseAccount(db, auth, 'interrupted-deletion');
  assert.equal((await db.doc('expense_tracker/users/users/interrupted-deletion/expenses/leftover').get()).exists,false);
  assert.equal((await db.doc('account_lifecycle/interrupted-deletion').get()).data().state,'complete');
});
