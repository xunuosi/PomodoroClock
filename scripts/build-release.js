const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

// 1. 确定关键路径
const projectRoot = path.resolve(__dirname, '../');
const profilePath = path.join(projectRoot, 'build-profile.json5');

// ✅ [核心逻辑] 跨平台命令适配
const isWin = os.platform() === 'win32';

// 工具 1: hvigorw
const hvigorName = isWin ? 'hvigorw.bat' : 'hvigorw';
const hvigorPath = path.join(projectRoot, hvigorName);

// 工具 2: ohpm (通常在环境变量中，直接调用命令即可)
// 如果环境变量没配好，可能需要指定绝对路径，这里假设已配置
const ohpmCmd = isWin ? 'ohpm.bat' : 'ohpm';

// --- 🔍 环境检查 ---

if (!fs.existsSync(profilePath)) {
    console.error("❌ Error: build-profile.json5 not found.");
    process.exit(1);
}

if (!fs.existsSync(hvigorPath)) {
    console.error(`❌ Error: '${hvigorName}' not found in project root.`);
    process.exit(1);
}

// 2. 获取密码
const password = process.env.RELEASE_PASS || process.argv[2];
if (!password) {
    console.error("❌ Error: Password not provided.");
    console.error("Usage: node scripts/build-release.js <PASSWORD>");
    process.exit(1);
}

// 备份原始内容
const originalContent = fs.readFileSync(profilePath, 'utf-8');

try {
    // 3. 注入密码
    console.log("🔄 Injecting signing secrets...");
    const newContent = originalContent.replace(/PASSWORD_PLACEHOLDER/g, password);
    fs.writeFileSync(profilePath, newContent);

    // 4. 执行构建流程

    // 步骤 A: 安装依赖 (确保环境干净)
    console.log(`📦 Installing dependencies (${ohpmCmd} install)...`);
    execSync(`${ohpmCmd} install`, { stdio: 'inherit', cwd: projectRoot });

    // 步骤 B: 清理旧构建 (可选，防止缓存问题)
    console.log(`🧹 Cleaning project...`);
    // Windows 上最好用双引号包裹路径
    const cleanCmd = `"${hvigorPath}" clean --mode release`;
    execSync(cleanCmd, { stdio: 'inherit', cwd: projectRoot });

    // 步骤 C: 正式打包
    console.log(`🚀 Building Release HAP...`);
    const buildCmd = `"${hvigorPath}" assembleHap --mode release`;
    execSync(buildCmd, { stdio: 'inherit', cwd: projectRoot });

    console.log("✅ Build Success! Release HAP generated.");

} catch (e) {
    console.error("❌ Build Failed:", e.message);
    // 这里的 catch 会捕获 ohpm 或 hvigor 的任何报错
} finally {
    // 5. 还原文件 (无论成功失败都要执行)
    console.log("cw Restoring build-profile.json5...");
    fs.writeFileSync(profilePath, originalContent);
}