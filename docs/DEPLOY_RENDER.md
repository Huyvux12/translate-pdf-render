# 🚀 Hướng Dẫn Deploy PDFMathTranslate lên Render.com

## Mục lục
- [Yêu cầu trước khi bắt đầu](#yêu-cầu)
- [Bước 1: Chuẩn bị repo](#bước-1-chuẩn-bị-repo)
- [Bước 2: Push code lên GitHub](#bước-2-push-code-lên-github)
- [Bước 3: Tạo tài khoản Render](#bước-3-tạo-tài-khoản-render)
- [Bước 4: Tạo Web Service](#bước-4-tạo-web-service)
- [Bước 5: Cấu hình Environment Variables](#bước-5-cấu-hình-environment-variables)
- [Bước 6: Deploy](#bước-6-deploy)
- [Bước 7: Kiểm tra & sử dụng](#bước-7-kiểm-tra--sử-dụng)
- [Troubleshooting](#troubleshooting)
- [Chi phí & Plan khuyến nghị](#chi-phí--plan-khuyến-nghị)

---

## Yêu cầu

Trước khi bắt đầu, bạn cần:

1. ✅ Tài khoản [GitHub](https://github.com) (để lưu code)
2. ✅ Tài khoản [Render](https://dashboard.render.com/register) (để deploy)
3. ✅ OpenAI-compatible API endpoint (URL + API key + model name)
4. ✅ 3 file cấu hình đã được tạo sẵn trong repo:
   - `Dockerfile.render`
   - `entrypoint.sh`
   - `render.yaml`

---

## Bước 1: Chuẩn bị Repo

Đảm bảo repo có đủ 3 file cấu hình:

```
PDFMathTranslate/
├── Dockerfile.render    ← Docker build cho Render
├── entrypoint.sh        ← Script khởi động với auth
├── render.yaml          ← Blueprint tự động
├── Dockerfile           ← (giữ nguyên, không sửa)
├── pdf2zh/              ← Source code
├── pyproject.toml       ← Dependencies
└── ...
```

### Kiểm tra nội dung các file:

**`Dockerfile.render`** — Build image Python 3.12 + cài dependencies + warmup model:
```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim
WORKDIR /app
# ... (cài system deps, Python deps, copy code)
RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
```

**`entrypoint.sh`** — Tạo file users.txt từ biến `AUTH_USERS` khi container khởi động:
```bash
#!/bin/bash
# Tạo users.txt từ AUTH_USERS="user1,pass1;user2,pass2"
if [ -n "$AUTH_USERS" ]; then
    echo "$AUTH_USERS" | tr ';' '\n' > /app/users.txt
    exec pdf2zh -i --serverport ${PORT:-7860} --authorized /app/users.txt
else
    exec pdf2zh -i --serverport ${PORT:-7860}
fi
```

**`render.yaml`** — Cấu hình auto-deploy:
```yaml
services:
  - type: web
    name: pdfmathtranslate
    runtime: docker
    plan: standard
    dockerfilePath: ./Dockerfile.render
    envVars:
      - key: AUTH_USERS
        sync: false
      - key: OPENAILIKED_BASE_URL
        sync: false
      # ... (xem file đầy đủ)
```

---

## Bước 2: Push Code lên GitHub

### Nếu chưa có repo trên GitHub:

```bash
# 1. Tạo repo mới trên GitHub (ví dụ: my-pdf-translator)
# 2. Trong thư mục project:

cd PDFMathTranslate

git init
git add .
git commit -m "Add Render deploy config"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-pdf-translator.git
git push -u origin main
```

### Nếu đã có repo, chỉ cần push 3 file mới:

```bash
git add Dockerfile.render entrypoint.sh render.yaml
git commit -m "Add Render deployment files"
git push
```

> ⚠️ **Quan trọng**: KHÔNG push file chứa API key hay password vào GitHub!
> Các thông tin nhạy cảm sẽ được cấu hình qua Environment Variables trên Render.

---

## Bước 3: Tạo Tài Khoản Render

1. Truy cập **https://dashboard.render.com/register**
2. Đăng ký bằng **GitHub account** (khuyến nghị — tự động liên kết repo)
3. Hoặc đăng ký bằng email → sau đó liên kết GitHub ở phần **Account Settings > Connected Accounts**

---

## Bước 4: Tạo Web Service

### Cách A: Dùng Blueprint (tự động — Khuyến nghị)

1. Truy cập [Render Dashboard](https://dashboard.render.com/)
2. Click nút **"New"** (góc trên bên phải) → chọn **"Blueprint"**
3. Chọn repo GitHub mà bạn vừa push lên
4. Render sẽ **tự động đọc** file `render.yaml` và hiện form cấu hình
5. Nhập các biến môi trường (xem [Bước 5](#bước-5-cấu-hình-environment-variables))
6. Click **"Apply"** → Render bắt đầu build

### Cách B: Tạo thủ công (nếu Blueprint không hoạt động)

1. Truy cập [Render Dashboard](https://dashboard.render.com/)
2. Click **"New"** → **"Web Service"**
3. Chọn **"Build and deploy from a Git repository"** → Click **"Next"**
4. Chọn repo GitHub của bạn → Click **"Connect"**
5. Điền thông tin:

| Field | Giá trị |
|---|---|
| **Name** | `pdfmathtranslate` _(hoặc tên bạn muốn)_ |
| **Region** | `Singapore` _(hoặc gần bạn nhất)_ |
| **Branch** | `main` |
| **Language** | ⚠️ **Chọn `Docker`** _(rất quan trọng!)_ |
| **Dockerfile Path** | `./Dockerfile.render` |
| **Instance Type** | `Standard` ($7/tháng) trở lên |

6. Mở phần **"Advanced"** để thêm Environment Variables
7. Click **"Create Web Service"**

---

## Bước 5: Cấu Hình Environment Variables

Trong phần **Environment** của service (hoặc khi tạo service), thêm các biến sau:

### Biến bắt buộc:

| Key | Value | Mô tả |
|---|---|---|
| `AUTH_USERS` | `admin,matkhau_cua_ban` | Username và password để login |
| `OPENAILIKED_BASE_URL` | `https://your-api.com/v1` | Base URL của OpenAI-compatible API |
| `OPENAILIKED_API_KEY` | `sk-xxxxxx` | API key |
| `OPENAILIKED_MODEL` | `tên-model` | Tên model (ví dụ: `gpt-4o-mini`) |

### Biến tùy chọn (đã có default):

| Key | Value | Mô tả |
|---|---|---|
| `ENABLED_SERVICES` | `OpenAI-liked` | Chỉ hiện service này trong dropdown |
| `HIDDEN_GRADIO_DETAILS` | `true` | Ẩn API key khỏi giao diện |
| `PYTHONUNBUFFERED` | `1` | Log hiện ngay, không buffer |

### Ví dụ cụ thể:

```
AUTH_USERS          = admin,MySecureP@ssw0rd
OPENAILIKED_BASE_URL = https://api.openai.com/v1
OPENAILIKED_API_KEY  = sk-proj-abc123xyz
OPENAILIKED_MODEL    = gpt-4o-mini
ENABLED_SERVICES     = OpenAI-liked
HIDDEN_GRADIO_DETAILS = true
```

### Nhiều user đăng nhập?

Dùng dấu `;` để phân tách:
```
AUTH_USERS = admin,password123;friend,hello456;colleague,work789
```
→ Sẽ tạo 3 tài khoản login riêng biệt.

### Muốn thêm Google/Bing translate miễn phí?

```
ENABLED_SERVICES = OpenAI-liked,Google,Bing
```

---

## Bước 6: Deploy

### Quá trình build tự động

Sau khi click **"Create Web Service"** hoặc **"Apply Blueprint"**, Render sẽ:

1. **Clone** repo từ GitHub
2. **Build Docker image** từ `Dockerfile.render`:
   - Cài system libraries (libgl, glib, etc.)
   - Cài Python dependencies (~20 packages)
   - Download & warmup BabelDOC ONNX model
   - Copy source code & install pdf2zh
3. **Start container** chạy `entrypoint.sh`

### Thời gian build:

| Lần | Thời gian | Lý do |
|---|---|---|
| Lần 1 | **10-15 phút** | Download tất cả, build from scratch |
| Lần 2+ | **3-5 phút** | Docker layer cache, chỉ build phần thay đổi |

### Theo dõi build:

- Vào service → tab **"Events"** → xem log build real-time
- Nếu build thành công, status sẽ chuyển sang **🟢 Live**
- Nếu build thất bại, đọc log lỗi ở tab **"Logs"**

---

## Bước 7: Kiểm Tra & Sử Dụng

### 7.1 Truy cập URL

Sau khi deploy thành công, Render cấp cho bạn URL dạng:
```
https://pdfmathtranslate-xxxx.onrender.com
```

Tìm URL này ở:
- Góc trên bên trái của trang service
- Hoặc trong tab **"Settings"** → mục **"URL"**

### 7.2 Đăng nhập

1. Mở URL trên trình duyệt
2. Hiện form đăng nhập Gradio:
   - **Username**: `admin` (hoặc tên bạn đã đặt)
   - **Password**: password bạn đã cấu hình trong `AUTH_USERS`
3. Click **"Login"**

### 7.3 Dịch PDF

1. Chọn **"File"** → Upload file PDF
2. Service đã tự chọn **"OpenAI-liked"** (vì `ENABLED_SERVICES`)
3. Chọn **ngôn ngữ nguồn** (ví dụ: English) và **ngôn ngữ đích** (ví dụ: Simplified Chinese)
4. Click **"Translate"**
5. Chờ progress bar → Download file kết quả:
   - **Mono**: File chỉ có bản dịch
   - **Dual**: File song ngữ (gốc + dịch)

---

## Troubleshooting

### ❌ Build fail: "Error: Out of memory"
**Nguyên nhân**: Plan quá nhỏ, không đủ RAM cho ONNX model
**Giải pháp**: Upgrade lên **Standard plan** ($7/tháng, 2GB RAM) trở lên

### ❌ "Port scan timeout" sau khi build thành công
**Nguyên nhân**: App không bind đúng PORT mà Render yêu cầu
**Giải pháp**: 
- Kiểm tra `entrypoint.sh` có dùng `${PORT:-7860}` không
- Xem log ở tab **"Logs"** để tìm port Gradio đang listen

### ❌ "The OPENAILIKED_BASE_URL is missing"
**Nguyên nhân**: Chưa cấu hình biến môi trường
**Giải pháp**: Vào **Environment** → thêm biến `OPENAILIKED_BASE_URL`

### ❌ Translation timeout / lỗi API
**Nguyên nhân**: API endpoint không truy cập được từ Render
**Giải pháp**: 
- Kiểm tra API endpoint có public access không
- Test API endpoint bằng curl:
  ```bash
  curl -X POST https://your-api.com/v1/chat/completions \
    -H "Authorization: Bearer sk-xxx" \
    -H "Content-Type: application/json" \
    -d '{"model":"your-model","messages":[{"role":"user","content":"Hello"}]}'
  ```

### ❌ Login không được (sai password)
**Nguyên nhân**: Biến `AUTH_USERS` format sai
**Giải pháp**: Đảm bảo format đúng: `username,password` (phân cách bằng dấu phẩy, KHÔNG có khoảng trắng)

### ❌ App bị sleep sau 15 phút
**Nguyên nhân**: Free/Starter plan tự tắt khi không có traffic  
**Giải pháp**: Upgrade lên Standard plan ($7/tháng) — service chạy 24/7

### ❌ Mất cache dịch thuật sau redeploy
**Nguyên nhân**: Render dùng ephemeral filesystem — file bị xóa khi restart
**Giải pháp**: Thêm **Render Disk** ($0.25/GB/tháng):
1. Vào service → **Settings** → **Disks**
2. Thêm disk với mount path: `/root/.cache/pdf2zh`
3. Size: 1 GB (đủ cho hàng ngàn bản dịch cached)

---

## Chi Phí & Plan Khuyến Nghị

| Plan | RAM | CPU | Giá | Phù hợp? |
|---|---|---|---|---|
| Free | 512 MB | 0.1 CPU | $0 | ❌ Không đủ RAM |
| Starter | 512 MB | 0.5 CPU | $1/tháng | ❌ Không đủ RAM |
| Starter Plus | 1 GB | 0.5 CPU | $3/tháng | ⚠️ Vừa đủ, có thể chậm |
| **Standard** | **2 GB** | **1 CPU** | **$7/tháng** | ✅ **Khuyến nghị** |
| Standard Plus | 4 GB | 1.5 CPU | $13/tháng | ✅ Tốt cho PDF lớn |
| Pro | 8 GB | 2 CPU | $25/tháng | ✅ Cho production heavy |

> 💡 **Tip**: Bắt đầu với **Standard ($7/tháng)**, nếu thấy chậm với PDF lớn thì upgrade lên Standard Plus.

---

## Cập Nhật Code

Khi bạn push code mới lên GitHub, Render sẽ **tự động redeploy** (nếu bật auto-deploy):

```bash
git add .
git commit -m "Update something"
git push
```

Hoặc trigger deploy thủ công: **Dashboard** → **Manual Deploy** → **Deploy latest commit**

---

## Thay Đổi Environment Variables

1. Vào service → tab **"Environment"**
2. Sửa giá trị biến
3. Click **"Save Changes"**
4. Render sẽ **tự động restart** service với config mới (không cần rebuild)
