#!/usr/bin/env node
/**
 * Nạp thư viện gợi ý (tips.json) lên Firestore: tips/{code}.
 *
 * Cách dùng (xem README.md cùng thư mục):
 *   npm install
 *   node seed.js --dry-run              # chỉ kiểm tra dữ liệu, không ghi
 *   node seed.js                        # ghi đè tips/{code}
 *   node seed.js --deactivate-missing   # tip có trên Firestore nhưng không còn trong JSON -> active=false
 *
 * Service account đọc qua biến môi trường GOOGLE_APPLICATION_CREDENTIALS.
 * TUYỆT ĐỐI không commit file service account lên Git.
 */
const path = require('path');

const GOALS = ['weight_loss', 'balanced', 'less_sugar'];
const CATEGORIES = ['drink', 'main_dish', 'snack', 'dessert'];
const LEVELS = ['low', 'medium', 'high'];
const LEVEL_KEYS = ['sugar_level', 'fat_level', 'carb_level', 'veg_level', 'protein_level', 'energy_level'];

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run');
const deactivateMissing = args.has('--deactivate-missing');

function validate(tips) {
  const errors = [];
  const seen = new Set();
  if (!Array.isArray(tips)) return ['tips.json phải là một mảng'];

  tips.forEach((tip, i) => {
    const where = `#${i} (${tip.code || '?'})`;
    if (!/^[a-z0-9_]{3,40}$/.test(tip.code || '')) errors.push(`${where}: code phải là snake_case`);
    if (seen.has(tip.code)) errors.push(`${where}: code bị trùng`);
    seen.add(tip.code);
    if (!tip.title || tip.title.length > 60) errors.push(`${where}: title trống hoặc quá dài (>60)`);
    if (!tip.content || tip.content.length > 200) errors.push(`${where}: content trống hoặc quá dài (>200)`);
    if (/calo|kcal|calorie/i.test(`${tip.title} ${tip.content}`)) errors.push(`${where}: không được nhắc tới calo`);
    if (!Array.isArray(tip.goals) || tip.goals.length === 0 || tip.goals.some((g) => !GOALS.includes(g))) {
      errors.push(`${where}: goals không hợp lệ`);
    }
    if (typeof tip.priority !== 'number') errors.push(`${where}: priority phải là số`);
    const appliesTo = tip.applies_to || {};
    for (const [key, values] of Object.entries(appliesTo)) {
      if (!Array.isArray(values)) {
        errors.push(`${where}: applies_to.${key} phải là mảng`);
      } else if (key === 'category') {
        if (values.some((v) => !CATEGORIES.includes(v))) errors.push(`${where}: category không hợp lệ`);
      } else if (LEVEL_KEYS.includes(key)) {
        if (values.some((v) => !LEVELS.includes(v))) errors.push(`${where}: ${key} không hợp lệ`);
      } else {
        errors.push(`${where}: khóa applies_to lạ "${key}"`);
      }
    }
  });
  return errors;
}

async function main() {
  const tips = require(path.join(__dirname, 'tips.json'));
  const errors = validate(tips);
  if (errors.length) {
    console.error('Dữ liệu tips.json chưa hợp lệ:\n- ' + errors.join('\n- '));
    process.exit(1);
  }
  console.log(`tips.json hợp lệ: ${tips.length} gợi ý.`);
  if (dryRun) return;

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('Thiếu biến môi trường GOOGLE_APPLICATION_CREDENTIALS (đường dẫn file service account).');
    process.exit(1);
  }

  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const batch = db.batch();
  for (const tip of tips) {
    batch.set(db.collection('tips').doc(tip.code), {
      code: tip.code,
      title: tip.title,
      content: tip.content,
      goals: tip.goals,
      applies_to: tip.applies_to || {},
      priority: tip.priority,
      source: tip.source || null,
      active: tip.active !== false,
      updated_at: now,
    });
  }

  if (deactivateMissing) {
    const codes = new Set(tips.map((t) => t.code));
    const existing = await db.collection('tips').get();
    existing.docs
      .filter((doc) => !codes.has(doc.id))
      .forEach((doc) => batch.update(doc.ref, { active: false, updated_at: now }));
  }

  await batch.commit();
  console.log(`Đã nạp ${tips.length} gợi ý vào collection "tips".`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
