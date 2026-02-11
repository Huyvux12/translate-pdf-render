# PDFMathTranslate — Tổng Hợp Phân Tích & Deploy

> **Repo**: [Byaidu/PDFMathTranslate](https://github.com/Byaidu/PDFMathTranslate)  
> **Package**: `pdf2zh` v1.9.11  
> **License**: AGPL-3.0 | **Python**: >=3.10, <3.13  
> **Tác giả**: Byaidu | **Accepted**: EMNLP 2025

---

## 1. Tổng Quan

Công cụ dịch PDF khoa học mã nguồn mở, **bảo toàn layout** (công thức toán, biểu đồ, mục lục, chú thích). Hỗ trợ 22+ dịch vụ dịch thuật, nhiều chế độ chạy (CLI, GUI, API, MCP).

---

## 2. Cấu Trúc Repo

```
PDFMathTranslate/
├── pdf2zh/                  # Source code chính (12 files, ~4500 dòng)
│   ├── __init__.py          # Export translate(), translate_stream()
│   ├── pdf2zh.py            # CLI entry point (argparse, main)
│   ├── translator.py        # 22+ translation engines (1079 dòng)
│   ├── converter.py         # PDF converter - xử lý layout & dịch
│   ├── high_level.py        # High-level API
│   ├── gui.py               # Gradio Web UI (892 dòng)
│   ├── config.py            # ConfigManager singleton (JSON config)
│   ├── doclayout.py         # DocLayout-YOLO ONNX model
│   ├── cache.py             # SQLite translation cache (peewee)
│   ├── pdfinterp.py         # PDF Interpreter mở rộng pdfminer
│   ├── backend.py           # Flask + Celery HTTP API
│   └── mcp_server.py        # MCP server (AI agents)
├── test/                    # Unit tests (4 files)
├── docs/                    # Documentation đa ngôn ngữ
├── script/                  # Build scripts
├── .github/workflows/       # CI/CD (test, publish, exe-build)
├── Dockerfile               # Docker build gốc
├── Dockerfile.render        # Docker build cho Render (custom)
├── entrypoint.sh            # Entrypoint script cho Render (auth + PORT)
├── render.yaml              # Render Blueprint
├── docker-compose.yml       # Docker Compose
└── pyproject.toml           # Dependencies & metadata
```

---

## 3. Kiến Trúc

### Luồng Xử Lý

```
User (CLI/GUI/API/MCP)
    → pdf2zh.py (routing)
    → high_level.py (translate/translate_stream)
    → pdfinterp.py (PDF parsing) + doclayout.py (YOLO layout detection)
    → converter.py (extract text, skip formulas/figures)
    → translator.py (gọi API dịch, multi-threaded)
    → cache.py (SQLite cache tránh dịch lại)
    → Output: *-mono.pdf + *-dual.pdf
```

### Chế Độ Hoạt Động

| Mode | Lệnh | Mô tả |
|---|---|---|
| CLI | `pdf2zh doc.pdf` | Dịch trực tiếp |
| GUI | `pdf2zh -i` | Gradio Web UI (port 7860) |
| HTTP API | `pdf2zh --flask` | Flask + Celery (cần Redis) |
| MCP STDIO | `pdf2zh --mcp` | Cho AI agents |
| MCP SSE | `pdf2zh --mcp --sse` | MCP qua SSE |
| BabelDOC | `pdf2zh --babeldoc` | Backend thử nghiệm |

---

## 4. Translation Engines (22+)

```
BaseTranslator (abstract)
├── GoogleTranslator         ← Mặc định, miễn phí
├── BingTranslator           ← Microsoft Bing
├── DeepLTranslator          ← DeepL API (cần key)
├── DeepLXTranslator         ← DeepLX self-hosted
├── OllamaTranslator         ← Ollama local LLM
├── XinferenceTranslator     ← Xinference local
├── OpenAITranslator         ← OpenAI GPT
│   ├── AzureOpenAITranslator
│   ├── ModelScopeTranslator
│   ├── ZhipuTranslator
│   ├── SiliconTranslator
│   ├── X302AITranslator
│   ├── GeminiTranslator
│   ├── GrokTranslator
│   ├── GroqTranslator
│   ├── DeepseekTranslator
│   ├── OpenAIlikedTranslator  ← Custom OpenAI-compatible ⭐
│   └── QwenMtTranslator
├── AzureTranslator
├── TencentTranslator
├── AnythingLLMTranslator
├── DifyTranslator
└── ArgosTranslator          ← Offline
```

### OpenAIlikedTranslator (dùng cho deploy)

Tương thích bất kỳ API nào theo chuẩn OpenAI (`/v1/chat/completions`):

| Biến | Mô tả |
|---|---|
| `OPENAILIKED_BASE_URL` | **Bắt buộc** — Base URL API |
| `OPENAILIKED_API_KEY` | API key (mặc định: `"openailiked"`) |
| `OPENAILIKED_MODEL` | Tên model |

---

## 5. Config System

- **File**: `~/.cache/pdf2zh/config.json`
- **Singleton**: `ConfigManager` (thread-safe, RLock)
- **Ưu tiên**: GUI input → env var → config file → default
- **Cache DB**: `~/.cache/pdf2zh/cache.v1.db` (SQLite, WAL mode)

### Biến Quan Trọng

| Biến | Mô tả |
|---|---|
| `ENABLED_SERVICES` | Giới hạn services hiện trên GUI |
| `HIDDEN_GRADIO_DETAILS` | Ẩn API key khỏi UI (`true`/`false`) |
| `PDF2ZH_DEMO` | Bật demo mode (reCAPTCHA + giới hạn) |
| `PDF2ZH_LANG_FROM/TO` | Ngôn ngữ mặc định |
| `PDF2ZH_VFONT` | Regex font công thức |

---

## 6. GUI (Gradio)

- **Port**: 7860 (configurable via `--serverport`)
- **Auth**: `--authorized users.txt` (format: `user,pass` mỗi dòng)
- **Demo mode** (`PDF2ZH_DEMO=true`): reCAPTCHA + chỉ Google + max 20 trang + 5MB
- **Public launch**: bind `0.0.0.0`
- **Features**: Upload/URL, chọn service, ngôn ngữ, trang, custom prompt, progress bar, cancel, BabelDOC toggle

---

## 7. Dependencies Chính

| Category | Packages |
|---|---|
| PDF | pdfminer-six, pymupdf, pikepdf, fontTools |
| AI/ML | onnx, onnxruntime, opencv-python-headless, numpy |
| Translation | openai, deepl, ollama, xinference-client, tencent, azure |
| Web UI | gradio, gradio_pdf |
| Backend | flask, celery (optional) |
| Cache | peewee (SQLite ORM) |
| Core | babeldoc (>=0.1.22, <0.3.0) |

---

## 8. Deploy Lên Render.com

### 8.1 Files Tạo Cho Render

| File | Mục đích |
|---|---|
| `Dockerfile.render` | Build image + dùng `entrypoint.sh` |
| `entrypoint.sh` | Tạo `users.txt` từ `AUTH_USERS` env → chạy pdf2zh với auth + `$PORT` |
| `render.yaml` | Blueprint (tùy chọn, có thể tạo thủ công) |

### 8.2 Tạo Web Service Thủ Công

**Bước 1 — Thông tin cơ bản:**

| Field | Giá trị |
|---|---|
| Name | `huyvux-pdf` (hoặc tên bạn muốn) |
| Language | **Docker** |
| Branch | `main` |
| Region | `Singapore (Southeast Asia)` |
| Instance Type | **Standard** ($25/month, 2GB RAM, 1 CPU) |

**Bước 2 — Environment Variables (6 biến):**

| Key | Value | Mô tả |
|---|---|---|
| `AUTH_USERS` | `admin,your_password` | Login GUI (format: `user,pass;user2,pass2`) |
| `OPENAILIKED_BASE_URL` | `https://your-api.com/v1` | URL API OpenAI-compatible |
| `OPENAILIKED_API_KEY` | `sk-xxxxx` | API key |
| `OPENAILIKED_MODEL` | `model-name` | Tên model |
| `ENABLED_SERVICES` | `OpenAI-liked` | Chỉ hiện service này |
| `HIDDEN_GRADIO_DETAILS` | `true` | Ẩn API key trên UI |

**Bước 3 — Advanced Settings:**

| Field | Giá trị |
|---|---|
| Dockerfile Path | **`./Dockerfile.render`** ⚠️ Bắt buộc! |
| Docker Command | _(để trống)_ |
| Pre-Deploy Command | _(để trống)_ |
| Health Check Path | _(để trống)_ ← Gradio không có `/healthz` |
| Registry Credential | No credential |
| Auto-Deploy | On Commit |

**Bước 4 — Disk (tùy chọn, để lưu cache dịch thuật):**

| Field | Giá trị |
|---|---|
| Mount Path | `/root/.cache/pdf2zh` |
| Size | **1 GB** (đủ cho hàng ngàn bản dịch) |

> Nếu không cần lưu cache → bỏ qua Disk, tiết kiệm ~$0.25/tháng.

### 8.3 Sau Khi Deploy

- **Build time**: ~10-15 phút (lần đầu), 3-5 phút (lần sau)
- **URL**: `https://huyvux-pdf-xxxx.onrender.com`
- **Login**: Nhập username/password đã cấu hình trong `AUTH_USERS`
- **Dùng**: Upload PDF → Chọn ngôn ngữ → Translate → Download mono/dual

### 8.4 Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|---|---|---|
| Out of memory | Plan quá nhỏ | Upgrade Standard+ |
| Port scan timeout | App không bind đúng PORT | Kiểm tra `entrypoint.sh` có `${PORT:-7860}` |
| OPENAILIKED_BASE_URL missing | Chưa set env var | Thêm vào Environment |
| Health check fail | `/healthz` không tồn tại | Xóa trắng Health Check Path |
| Login sai | AUTH_USERS format sai | Format: `user,pass` (không có khoảng trắng) |
| Mất cache sau redeploy | Ephemeral filesystem | Gắn Disk mount `/root/.cache/pdf2zh` |

### 8.5 Chi Phí Ước Tính

| Thành phần | Chi phí |
|---|---|
| Standard instance | $25/tháng |
| Disk 1GB (tùy chọn) | $0.25/tháng |
| **Tổng** | **~$25/tháng** |

---

## 9. Đánh Giá Repo

### Điểm mạnh ✅
- 22+ dịch vụ dịch (đa dạng nhất)
- Bảo toàn layout với YOLO detection + PDF patching
- Translation cache (SQLite) tránh dịch lại
- Multi-interface (CLI, GUI, API, MCP)
- Multi-threading dịch song song
- Docker-ready, deploy dễ
- Bilingual output (mono + dual)
- Custom prompts cho LLM
- Offline support (Argos + Ollama)
- Published tại EMNLP 2025

### Điểm yếu ⚠️
- `translator.py` quá lớn (1079 dòng, 22 classes) — nên tách package
- `gui.py` phức tạp (892 dòng) — mix logic + UI
- Không có database migration
- Cache key giới hạn 20 chars
- 20+ direct dependencies
- Thiếu type hints nhiều chỗ
- Logging không nhất quán (`log` vs `logger`)
