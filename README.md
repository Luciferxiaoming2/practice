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

### 1. 创建第一个管理员账号
后端启动后，访问 `http://localhost:8000/docs`，调用 `POST /users/` 创建初始管理员：
```json
{
  "username": "admin",
  "full_name": "管理员",
  "password": "your_password",
  "is_admin": true
}
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

### 6. Web 端 API 地址（可选）
在 `web/` 目录下创建 `.env.local`：
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```
默认已回退到 `http://localhost:8000`，本地开发无需配置。

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
| GPS 打卡 | — | ✅ |
| 时间段验证 | — | ✅ |
| 打卡记录 | 🚧 | 🚧 |

✅ 已完成　🚧 待开发
