// Read-only inspection using the Firebase CLI's existing authenticated session.
const fs = require('node:fs');
const path = require('node:path');
const cli = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {logger} = require(path.join(cli,'logger'));
logger.silent = true;
const auth = require(path.join(cli,'auth'));
const {requireAuth} = require(path.join(cli,'requireAuth'));
const {Client} = require(path.join(cli,'apiv2'));
const project = 'emergio-f2ef7';
async function read(origin, url, apiVersion = 'v1') {
  try { return (await new Client({urlPrefix:origin,apiVersion}).get(url)).body; }
  catch (e) { return {inspectionError: e.status || e.message}; }
}
(async () => {
  const account = auth.getGlobalDefaultAccount();
  await requireAuth({project, user:account.user, tokens:account.tokens});
  const billing = await read('https://cloudbilling.googleapis.com',`projects/${project}/billingInfo`);
  const releases = await read('https://firebaserules.googleapis.com',`projects/${project}/releases`);
  const config = await read('https://identitytoolkit.googleapis.com/admin',`projects/${project}/config`, 'v2');
  const google = await read('https://identitytoolkit.googleapis.com/admin',`projects/${project}/defaultSupportedIdpConfigs/google.com`, 'v2');
  const hosting = await read('https://firebasehosting.googleapis.com',`projects/${project}/sites/${project}/releases`, 'v1beta1');
  const summary = {billingEnabled:billing.billingEnabled, billingError:billing.inspectionError,
    auth:{emailPassword:config.signIn?.email?.enabled, google:google.enabled, error:config.inspectionError},
    releases:releases.releases || releases,
    hostingReleaseCount:hosting.releases?.length,hostingError:hosting.inspectionError};
  for (const release of releases.releases || []) {
    if (release.name.endsWith('/cloud.firestore')) {
      const ruleset = await read('https://firebaserules.googleapis.com',release.rulesetName);
      for (const file of ruleset.source?.files || []) {
        fs.writeFileSync('.cache/deployed-firestore.rules',file.content);
        summary.firestoreBackup = '.cache/deployed-firestore.rules';
      }
    }
  }
  fs.writeFileSync('.cache/firebase-inspection.json',JSON.stringify(summary,null,2));
  console.log(JSON.stringify(summary,null,2));
})().catch(() => { console.error('Firebase inspection failed. No cloud changes made.'); process.exitCode=1; });
