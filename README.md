# 熵析云枢打卡系统

## 项目结构

```
one/
├── backend/     FastAPI + SQLite 后端
├── web/         Next.js 管理端
├── mobile/      Flutter 移动端（iOS / Android）
└── docs/        项目文档
```

---

## 快速启动

### 1. 后端（FastAPI）
```bash
cd backend
D:\uv\venvs\practice\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# API 文档: http://localhost:8000/docs
```

### 2. Web 管理端（Next.js）
```bash
cd web
npm run dev -- --port 3000
# 访问: http://localhost:3000
```

### 3. 移动端（Flutter）

#### Android 真机 USB 调试

**Step 1：USB 连接真机并开启开发者模式 + USB 调试**

**Step 2：设置 adb 端口转发**（让真机通过 USB 访问电脑的后端）
```bash
adb reverse tcp:8000 tcp:8000
```

**Step 3：确认设备已连接**
```bash
flutter devices
```

**Step 4：运行到真机**
```bash
cd mobile
flutter run -d <设备ID>
```

> `<设备ID>` 从 `flutter devices` 输出中获取，例如 `401F5U03ZM0000H`。

**注意：** 使用 `adb reverse` 后，移动端 API 地址保持 `http://127.0.0.1:8000` 即可，无需改为局域网 IP。

#### iOS 模拟器调试

**Step 1：安装 CocoaPods 依赖**
```bash
cd mobile/ios
pod install
```

**Step 2：启动 iOS 模拟器**
```bash
open -a Simulator
```

**Step 3：确认模拟器已连接**
```bash
flutter devices
```

**Step 4：运行到模拟器**
```bash
cd mobile
flutter run -d <模拟器ID>
```

> iOS 模拟器可直接访问 `http://127.0.0.1:8000`，无需额外配置端口转发。

#### iOS 真机调试

**Step 1：安装 CocoaPods 依赖**
```bash
cd mobile/ios
pod install
```

**Step 2：使用 Xcode 配置签名**
1. 打开 `mobile/ios/Runner.xcworkspace`（注意是 `.xcworkspace` 不是 `.xcodeproj`）
2. 选择 Runner 项目 → Signing & Capabilities
3. 选择你的 Apple Developer Team
4. 修改 Bundle Identifier（如 `com.yourcompany.attendance`）

**Step 3：USB 连接 iPhone 并信任电脑**

**Step 4：确认设备已连接**
```bash
flutter devices
```

**Step 5：运行到真机**
```bash
cd mobile
flutter run -d <设备ID>
```

> iOS 真机需要通过 Wi-Fi 或修改 API 地址为电脑局域网 IP（如 `http://192.168.1.x:8000`）来访问后端。

### 一键启动（Windows）

也可以直接双击项目根目录的 `start.bat` 启动后端和 Web 端，双击 `stop.bat` 停止。移动端仍需手动执行上述 Step 2-4。

---

## ⚠️ 需要手动配置的内容

### 0. 开发环境要求

#### 后端
- Python 3.8+
- pip 或 uv

#### Web 管理端
- Node.js 16+
- npm 或 yarn

#### 移动端
- Flutter 3.0+
- Dart 2.17+

**Android 开发：**
- Android Studio
- Android SDK (API 21+)
- Java JDK 11+

**iOS 开发（仅限 macOS）：**
- macOS 12.0 (Monterey) 或更高版本
- Xcode 14.0 或更高版本
- CocoaPods 1.11+
- Apple Developer 账号（真机调试需要）

### 1. 默认超级管理员账号
| 账号 | 密码 | 角色 |
|------|------|------|
| `admin` | `admin123` | 管理员 |

如需重新创建，可运行脚本：
```bash
cd backend
python scripts/create_admin.py
```

### 2. 后端安全密钥（生产环境必须修改）
编辑 `backend/app/core.py`，将以下值替换为随机强密钥：
```python
SECRET_KEY = "change-me-in-production"
```

### 3. 移动端 API 地址
配置文件：`mobile/lib/core/config.dart`
- **真机 USB 调试（推荐）**：保持 `http://127.0.0.1:8000`，配合 `adb reverse tcp:8000 tcp:8000`
- **Android 模拟器**：使用 `http://10.0.2.2:8000`
- **iOS 模拟器**：使用 `http://127.0.0.1:8000`
- **Wi-Fi 调试**：替换为电脑局域网 IP，如 `http://192.168.1.x:8000`（需开放防火墙 8000 端口）

### 4. Android 权限配置
在 `mobile/android/app/src/main/AndroidManifest.xml` 中添加：
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. iOS 配置

**首次运行前安装依赖：**
```bash
cd mobile/ios
pod install
```

**配置高德地图 Key：**
将 `mobile/ios/Runner/Info.plist` 中的 `您的高德iOS_Key` 替换为实际申请的 [高德iOS Key](https://console.amap.com/)

> 权限配置已完成，无需额外修改。如遇 CocoaPods 问题可执行 `pod repo update`

### 6. Web 端环境配置
在 `web/.env.local` 中配置：
```
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_AMAP_KEY=您的高德Key
```
- API 地址默认回退到 `http://localhost:8000`，本地开发无需修改
- 高德 Key 需到 [高德开放平台](https://console.amap.com/) 申请 Web端(JS API) Key

### 7. 中国大陆网络环境配置（Gradle 镜像）

如果在中国大陆直接运行 `flutter run` 构建 Android 时出现 `Connection timed out`，需要将 Gradle 下载源切换为国内镜像：

**文件：** `mobile/android/gradle/wrapper/gradle-wrapper.properties`

将 `distributionUrl` 从官方源：
```
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
```
替换为腾讯云镜像：
```
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.14-all.zip
```

> Maven 仓库镜像已在 `mobile/android/build.gradle.kts` 和 `mobile/android/settings.gradle.kts` 中配置了阿里云镜像，无需额外修改。

### 8. 人脸识别（待接入）
当前移动端人脸录入仅拍照并标记 `face_enrolled=true`，未接入真实识别算法。
如需接入，在 `mobile/lib/screens/auth/setup_face_screen.dart` 的 `_submit()` 方法中
上传照片到后端，并在后端集成第三方人脸 SDK（如阿里云、腾讯云人脸核身）。

---

## 功能清单

| 功能 | Web 管理端 | Android | iOS |
|------|-----------|---------|-----|
| 登录 | ✅ | ✅ | ✅ |
| 新建账户 | ✅ | — | — |
| 重置密码 | ✅ | ✅ | ✅ |
| 重置人脸 | ✅ | — | — |
| 配置打卡规则 | ✅ | — | — |
| 首次登录引导 | — | ✅ | ✅ |
| 人脸录入 | — | ✅（待接入SDK）| ✅（待接入SDK）|
| GPS 打卡 | ✅（高德地图）| ✅ | ✅ |
| 时间段验证 | ✅ | ✅ | ✅ |
| 打卡记录 | ✅ | 🚧 | 🚧 |
| RBAC 角色权限 | ✅ | — | — |

✅ 已完成　🚧 待开发

---

## CI/CD 与部署

### 架构
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Web端   │────▶│          │◀────│  移动端  │
│ (Vercel) │     │  后端API │     │ (Flutter)│
└──────────┘     │ (云服务器)│     └──────────┘
                 └──────────┘
```
Web 端、Android、iOS 共用同一个后端 API。

### GitHub Actions

| Workflow | 触发条件 | 作用 |
|----------|---------|------|
| `ci.yml` | push/PR to master | 前端 TypeScript 检查 + 构建；后端导入检查 + 测试 |
| `deploy-web.yml` | push to master（web/ 变更）| 自动部署 Web 端到 Vercel |

### Vercel 部署配置

1. 在 [Vercel](https://vercel.com) 导入 GitHub 仓库
2. 在 GitHub 仓库 Settings → Secrets and variables → Actions 中添加：

**Secrets（必填）：**
| 名称 | 说明 |
|------|------|
| `VERCEL_TOKEN` | Vercel 个人 Token（Settings → Tokens） |
| `VERCEL_ORG_ID` | Vercel 团队/个人 ID |
| `VERCEL_PROJECT_ID` | Vercel 项目 ID |

**Variables（必填）：**
| 名称 | 说明 | 示例 |
|------|------|------|
| `NEXT_PUBLIC_API_URL` | 后端 API 地址 | `https://api.your-domain.com` |
| `NEXT_PUBLIC_AMAP_KEY` | 高德地图 JS API Key | `xxxxxxxxxxxxxxxx` |

> 获取 Vercel ID：运行 `npx vercel link`，在 `.vercel/project.json` 中查看 `orgId` 和 `projectId`。

### 后端部署
后端需部署到支持 Python 的云服务器，确保：
1. 修改 `backend/app/core.py` 中的 `SECRET_KEY`
2. 配置 CORS 允许 Vercel 域名和移动端访问
3. 启动命令：`uvicorn app.main:app --host 0.0.0.0 --port 8000`
