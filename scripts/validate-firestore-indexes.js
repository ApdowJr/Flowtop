#!/usr/bin/env node
// Validates firestore.indexes.json with the same validator `firebase deploy`
// uses, so an invalid file fails in CI instead of at deploy time.
//
// Usage: node scripts/validate-firestore-indexes.js [path/to/firestore.indexes.json]
const fs = require('node:fs');
const path = require('node:path');
const { FirestoreApi } = require('firebase-tools/lib/firestore/api');

const file = path.resolve(process.argv[2] || 'firestore.indexes.json');
const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
const api = new FirestoreApi();

try {
  const spec = api.upgradeOldSpec({
    indexes: raw.indexes,
    fieldOverrides: raw.fieldOverrides,
  });
  api.validateSpec(spec);
  console.log(
    `${path.basename(file)} is valid: ` +
      `${spec.indexes.length} composite indexes, ` +
      `${spec.fieldOverrides.length} field overrides.`,
  );
} catch (error) {
  console.error(`${path.basename(file)} is invalid: ${error.message}`);
  process.exit(1);
}
