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

### 后端
```bash
D:\uv\venvs\practice\Scripts\activate
cd backend
uvicorn app.main:app --reload
# API 文档: http://localhost:8000/docs
```

### Web 管理端
```bash
cd web
npm run dev
# 访问: http://localhost:3000
```

### 移动端
```bash
cd mobile
flutter run
```

---

## ⚠️ 需要手动配置的内容

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
编辑 `mobile/lib/core/api.dart`：
- Android 模拟器使用 `http://10.0.2.2:8000`（默认已配置）
- iOS 模拟器使用 `http://localhost:8000`（取消注释对应行）
- 真机调试需替换为电脑的局域网 IP，例如 `http://192.168.1.x:8000`

### 4. Android 权限配置
在 `mobile/android/app/src/main/AndroidManifest.xml` 中添加：
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. iOS 权限配置
在 `mobile/ios/Runner/Info.plist` 中添加：
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>打卡需要获取您的位置</string>
<key>NSCameraUsageDescription</key>
<string>打卡需要使用摄像头进行人脸识别</string>
```

### 6. Web 端环境配置
在 `web/.env.local` 中配置：
```
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_AMAP_KEY=您的高德Key
```
- API 地址默认回退到 `http://localhost:8000`，本地开发无需修改
- 高德 Key 需到 [高德开放平台](https://console.amap.com/) 申请 Web端(JS API) Key

### 7. 人脸识别（待接入）
当前移动端人脸录入仅拍照并标记 `face_enrolled=true`，未接入真实识别算法。
如需接入，在 `mobile/lib/screens/auth/setup_face_screen.dart` 的 `_submit()` 方法中
上传照片到后端，并在后端集成第三方人脸 SDK（如阿里云、腾讯云人脸核身）。

---

## 功能清单

| 功能 | Web 管理端 | Flutter 移动端 |
|------|-----------|--------------|
| 登录 | ✅ | ✅ |
| 新建账户 | ✅ | — |
| 重置密码 | ✅ | ✅ |
| 重置人脸 | ✅ | — |
| 配置打卡规则 | ✅ | — |
| 首次登录引导 | — | ✅ |
| 人脸录入 | — | ✅（待接入SDK）|
| GPS 打卡 | ✅（高德地图）| ✅ |
| 时间段验证 | ✅ | ✅ |
| 打卡记录 | ✅ | 🚧 |
| RBAC 角色权限 | ✅ | — |

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
