# Setup API Keys untuk Task Scheduler App

## 🚨 PENTING: Keamanan API Keys

API keys yang sensitif TIDAK BOLEH di-commit ke version control (Git). File ini akan membantu Anda setup API keys dengan aman.

## 📁 File yang Perlu Diperhatikan

### 1. `.gitignore` (Sudah dikonfigurasi)
File berikut sudah ditambahkan ke `.gitignore` untuk mencegah commit:
- `lib/core/constants/api_keys.dart` - File actual API keys
- `*.env` - Environment files
- `config/` - Directory konfigurasi
- `secrets/` - Directory secrets
- `local_config.dart` - Config lokal

### 2. `api_keys.dart.template` (Template)
File template yang bisa di-copy sebagai panduan:
```bash
cp lib/core/constants/api_keys.dart.template lib/core/constants/api_keys.dart
```

## 🔧 Cara Setup API Keys

### Step 1: Copy Template
```bash
# Copy template ke file actual
cp lib/core/constants/api_keys.dart.template lib/core/constants/api_keys.dart
```

### Step 2: Isi API Keys
Edit file `lib/core/constants/api_keys.dart` dan ganti placeholder dengan API keys Anda:

```dart
class ApiKeys {
  // Ganti dengan API key Groq Anda
  static const String groqApiKey = 'gsk_YOUR_ACTUAL_API_KEY_HERE';
  
  // API keys lainnya (jika ada)
  // static const String openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
}
```

### Step 3: Verifikasi Setup
Aplikasi akan otomatis:
1. Mendeteksi jika API key tidak valid atau kosong
2. Menggunakan fallback insights dalam Bahasa Indonesia
3. Menampilkan fungsi dasar tanpa AI

## 🔑 Mendapatkan API Keys

### Groq API (Untuk AI Insights)
1. Kunjungi https://console.groq.com/
2. Sign up atau login
3. Buat API key baru
4. Copy dan paste ke file `api_keys.dart`

### API Keys Lainnya (Opsional)
Tambahkan API keys lain jika diperlukan untuk fitur tambahan.

## 🛡️ Best Practices Keamanan

### ✅ YANG DILAKUKAN:
- ✅ API keys di `.gitignore`
- ✅ Template file untuk panduan
- ✅ Fallback tanpa API keys
- ✅ Validasi API key di runtime

### ❌ YANG DIHINDARI:
- ❌ Hardcode API keys di code
- ❌ Commit API keys ke Git
- ❌ Share API keys di public forum
- ❌ Use API keys di client-side production

## 🚀 Testing Setup

### 1. Tanpa API Keys
Aplikasi akan berjalan dengan:
- Default insights dalam Bahasa Indonesia
- Generic task steps berdasarkan pola umum
- Semua fitur basic tersedia

### 2. Dengan API Keys
Aplikasi akan memiliki:
- AI-powered insights yang personal
- Task steps yang lebih akurat
- Analytics yang lebih cerdas

## 📝 Troubleshooting

### Error: "AI Error"
- Pastikan API key valid dan aktif
- Check koneksi internet
- Verify API quota tidak habis

### Error: "Missing API Key"
- Pastikan file `api_keys.dart` ada
- Verify format API key benar
- Check tidak ada typo di nama variable

### Aplikasi Tetap Berjalan
Jika API keys tidak tersedia, aplikasi akan:
- Tetap berfungsi normal
- Menggunakan fallback logic
- Menampilkan pesan yang informatif

## 🔄 Untuk Tim Development

### Setup untuk Developer Baru:
1. Clone repository
2. Copy template: `cp lib/core/constants/api_keys.dart.template lib/core/constants/api_keys.dart`
3. Isi dengan API keys pribadi
4. Jalankan aplikasi

### Ketika Pulling Changes:
- File `api_keys.dart` tidak akan berubah (di-ignore)
- Template mungkin update, salin ulang jika perlu
- API keys Anda tetap aman

## 📞 Support

Jika ada masalah dengan setup API keys:
1. Check file `.gitignore` sudah benar
2. Verify file permissions
3. Pastikan tidak ada API keys yang ter-commit accidentally
4. Gunakan `git history` untuk check jika perlu

---

**CATATAN**: API key yang sebelumnya ada di repository sudah di-revoke dan diganti dengan placeholder untuk keamanan.