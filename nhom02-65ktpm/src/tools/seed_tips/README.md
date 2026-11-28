# Nạp thư viện gợi ý (tips) lên Firestore

Thư viện gợi ý nằm trong `tips.json`. Mỗi gợi ý được ghi vào `tips/{code}`.
Ứng dụng chỉ **đọc** collection này (Security Rules chặn ghi từ client),
AI chỉ được **chọn mã** gợi ý, không tự viết lời khuyên.

## Cấu trúc một gợi ý

```json
{
  "code": "less_sugar_drink",
  "title": "Gọi ít đường",
  "content": "Lần sau thử gọi 30–50% đường, vị vẫn ngon mà nhẹ nhàng hơn nhiều.",
  "goals": ["weight_loss", "less_sugar", "balanced"],
  "applies_to": { "category": ["drink"], "sugar_level": ["high", "medium"] },
  "priority": 10,
  "source": "Khuyến nghị chung về hạn chế đường bổ sung"
}
```

- `applies_to`: điều kiện lọc. **AND** giữa các khóa, **OR** trong từng mảng.
  Khóa hợp lệ: `category`, `sugar_level`, `fat_level`, `carb_level`,
  `veg_level`, `protein_level`, `energy_level`. Để `{}` nếu áp dụng cho mọi món.
- `priority`: số lớn hơn được ưu tiên.
- `active` (tùy chọn, mặc định `true`): đặt `false` để tạm ẩn gợi ý.

Quy tắc nội dung: hành động cụ thể, giọng tích cực, **không** nhắc calo,
**không** lời khuyên y tế/bệnh lý, không ăn kiêng cực đoan.

## Các bước nạp

1. **Duyệt nội dung `tips.json` trước khi nạp** (cả nhóm đọc lại).
2. Firebase Console → Project settings → Service accounts → *Generate new private key*.
   Lưu file **ngoài thư mục repo**, ví dụ `D:\keys\nutritrack-service-account.json`.
3. Cài thư viện và kiểm tra dữ liệu:

   ```powershell
   cd nhom02-65ktpm/src/tools/seed_tips
   npm install
   npm run check
   ```

4. Nạp dữ liệu (PowerShell):

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = "D:\keys\nutritrack-service-account.json"
   npm run seed
   ```

5. Mở Firestore trong Firebase Console để kiểm tra collection `tips`.

> Không bao giờ commit file service account. `.gitignore` đã chặn
> `*serviceAccount*.json` và `service-account*.json`.
