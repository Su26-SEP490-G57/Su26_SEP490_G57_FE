/**
 * Script set Firebase custom claims cho user
 *
 * Setup:
 *   1. npm install firebase-admin
 *   2. Download service account key từ Firebase Console:
 *      Project Settings → Service accounts → Generate new private key
 *      Lưu file vào scripts/serviceAccountKey.json
 *   3. node set-role.js <email> <role>
 *
 * Ví dụ:
 *   node set-role.js nurse@poms.vn nurse
 *   node set-role.js patient@poms.vn patient
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const [email, role] = process.argv.slice(2);

if (!email || !role) {
    console.error('Usage: node set-role.js <email> <role>');
    console.error('Roles: nurse | patient');
    process.exit(1);
}

if (!['nurse', 'patient'].includes(role)) {
    console.error(`Invalid role: "${role}". Must be "nurse" or "patient"`);
    process.exit(1);
}

async function setRole() {
    try {
        const user = await admin.auth().getUserByEmail(email);
        await admin.auth().setCustomUserClaims(user.uid, { role });
        console.log(`✅ Set role "${role}" for ${email} (uid: ${user.uid})`);
        console.log('   User must sign out and sign in again for claims to take effect.');
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        process.exit(0);
    }
}

setRole();
