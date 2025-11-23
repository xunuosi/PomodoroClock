const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ALGORITHM = 'aes-256-cbc';
const KEY_FILE = path.join(__dirname, 'master.key');
const DATA_FILE = path.join(__dirname, 'encrypted.dat');

// 1. 获取或生成主密钥 (钥匙)
function getMasterKey() {
    if (fs.existsSync(KEY_FILE)) {
        // ✅ [修复] 正确读取 Key
        const hexKey = fs.readFileSync(KEY_FILE, 'utf-8').trim();
        return Buffer.from(hexKey, 'hex');
    }
    // 如果没有，生成一个新的并保存
    const key = crypto.randomBytes(32);
    fs.writeFileSync(KEY_FILE, key.toString('hex'));
    console.log(`🔑 New master key generated: ${KEY_FILE}`);
    console.log("⚠️  KEEP THIS FILE SAFE AND DO NOT COMMIT IT!");
    return key;
}

// 2. 加密 (锁)
function encrypt(text) {
    const key = getMasterKey();
    const iv = crypto.randomBytes(16); // 随机向量
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    // 保存格式: IV:密文
    const payload = iv.toString('hex') + ':' + encrypted;
    fs.writeFileSync(DATA_FILE, payload);
    console.log(`🔒 Password encrypted to: ${DATA_FILE}`);
}

// 3. 解密 (开)
function decrypt() {
    if (!fs.existsSync(KEY_FILE)) {
        throw new Error("❌ Master key not found! Cannot decrypt.");
    }
    if (!fs.existsSync(DATA_FILE)) {
        throw new Error("❌ Encrypted data file not found!");
    }

    const key = getMasterKey(); // ✅ 复用修复后的读取逻辑
    const payload = fs.readFileSync(DATA_FILE, 'utf-8');
    const parts = payload.split(':');
    const iv = Buffer.from(parts.shift(), 'hex');
    const encryptedText = parts.join(':');

    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

module.exports = { encrypt, decrypt };

// --- 命令行支持 ---
if (require.main === module) {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.log("Usage:");
        console.log("  Encrypt: node scripts/cipher.js \"YOUR_PASSWORD\"");
        console.log("  Decrypt: node scripts/cipher.js view");
    } else if (args[0] === 'view') {
        try {
            console.log("🔓 Decrypted password:", decrypt());
        } catch (e) { console.error(e.message); }
    } else {
        encrypt(args[0]);
    }
}