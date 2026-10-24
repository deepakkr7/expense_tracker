// Run through Firebase Emulator Suite; never against a production project.
const {test, before, after} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, deleteDoc, updateDoc} = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-spendwise',
    firestore:{rules:fs.readFileSync(path.join(__dirname,'../../firestore.rules'),'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
test('financial records are isolated; profile enumeration and backend-only writes denied', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const anon = env.unauthenticatedContext().firestore();
  const path = 'expense_tracker/users/users/alice';
  await assertSucceeds(setDoc(doc(alice,path),{id:'alice',name:'Alice'}));
  await assertSucceeds(setDoc(doc(alice,`${path}/expenses/one`),{amount:12}));
  await assertSucceeds(getDoc(doc(alice,`${path}/expenses/one`)));
  await assertFails(getDoc(doc(bob,path)));
  await assertFails(getDoc(doc(bob,`${path}/expenses/one`)));
  await assertFails(setDoc(doc(bob,`${path}/expenses/one`),{amount:99}));
  await assertFails(getDoc(doc(anon,path)));
  await assertFails(getDocs(collection(alice,'expense_tracker/users/users')));
  await assertFails(updateDoc(doc(alice,path),{id:'bob'}));
  await assertFails(deleteDoc(doc(alice,path)));
  await assertFails(setDoc(doc(alice,'account_lifecycle/alice'),{deleting:false}));
  await assertFails(setDoc(doc(alice,'service_usage/alice/actions/ai'),{count:0}));
  // Unrelated shared-project paths retain their existing authenticated policy.
  await assertSucceeds(setDoc(doc(alice,'unrelated_app_data/example'),{value:1}));
  await assertFails(getDoc(doc(anon,'unrelated_app_data/example')));
  await assertFails(setDoc(doc(alice,`${path}/ai_reports/one`),{reason:'test'}));
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(),'account_lifecycle/alice'),{deleting:true});
  });
  await assertFails(setDoc(doc(alice,`${path}/expenses/two`),{amount:12}));
  await assertFails(getDoc(doc(alice,path)));
});
