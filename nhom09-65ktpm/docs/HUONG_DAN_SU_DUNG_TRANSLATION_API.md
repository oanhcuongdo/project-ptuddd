# TÃ i Liá»‡u HÆ°á»›ng Dáº«n Sá»­ Dá»¥ng API Dá»‹ch Tá»©c ThÃ¬ (Instant Translation Service)

- **Há»c pháº§n:** PhÃ¡t Triá»ƒn á»¨ng Dá»¥ng Di Äá»™ng (PTUDDD) - Lá»›p 65KTPM
- **Dá»± Ã¡n:** BuddyTalk - á»¨ng dá»¥ng ká»· luáº­t cÃ¡ nhÃ¢n cáº£i thiá»‡n ká»¹ nÄƒng giao tiáº¿p vÃ  vÆ°á»£t rÃ o cáº£n ngÃ´n ngá»¯
- **PhÃ¢n há»‡:** KÃ¨m Online: Chat Thá»±c Chiáº¿n 1-1 & Dá»‹ch Tá»©c ThÃ¬
- **NgÆ°á»i thá»±c hiá»‡n:** TrÆ°Æ¡ng Tuáº¥n Háº£i (MSSV: 2351170590)

---

## 1. Giá»›i thiá»‡u chá»©c nÄƒng

Trong phÃ¢n há»‡ phÃ²ng chat thá»±c chiáº¿n 1-1 cá»§a BuddyTalk, ngÆ°á»i há»c thÆ°á»ng ghÃ©p Ä‘Ã´i vá»›i báº¡n Ä‘á»“ng hÃ nh bÃ¹ trá»« ngÃ´n ngá»¯ (VÃ­ dá»¥: NgÆ°á»i Viá»‡t kÃ¨m ngÆ°á»i nÆ°á»›c ngoÃ i). Khi gáº·p cÃ¢u nÃ³i khÃ³ hiá»ƒu hoáº·c tá»« vá»±ng má»›i, ngÆ°á»i dÃ¹ng chá»‰ cáº§n nháº¥n nÃºt **"Dá»‹ch tá»©c thÃ¬"** cáº¡nh tin nháº¯n, há»‡ thá»‘ng sáº½ dá»‹ch ngay láº­p tá»©c mÃ  khÃ´ng cáº§n thoÃ¡t á»©ng dá»¥ng sang Google Dá»‹ch.

## 2. CÃ¡c tÃ­nh nÄƒng ká»¹ thuáº­t ná»•i báº­t

1. **Tá»‘c Ä‘á»™ pháº£n há»“i cá»±c nhanh (< 200ms):** Sá»­ dá»¥ng Google Translate Client GTX cÃ´ng khai, khÃ´ng cáº§n Ä‘Äƒng kÃ½ API Key phá»©c táº¡p hay tráº£ phÃ­.
2. **Bá»™ nhá»› Ä‘á»‡m thÃ´ng minh (In-memory Cache):** Tá»± Ä‘á»™ng lÆ°u trá»¯ cÃ¡c cÃ¢u Ä‘Ã£ dá»‹ch trong phiÃªn chat. Khi ngÆ°á»i dÃ¹ng báº¥m láº¡i nÃºt dá»‹ch hoáº·c lÆ°á»›t qua láº¡i tin nháº¯n cÅ©, há»‡ thá»‘ng láº¥y káº¿t quáº£ ngay trong 0ms tá»« Cache, tiáº¿t kiá»‡m 100% bÄƒng thÃ´ng máº¡ng.
3. **Dá»‹ch 2 chiá»u linh hoáº¡t:** Há»— trá»£ dá»‹ch chuyÃªn sÃ¢u `Anh -> Viá»‡t`, `Viá»‡t -> Anh`, hoáº·c `Tá»± Ä‘á»™ng nháº­n diá»‡n (Auto)`.
4. **KhÃ´ng phá»¥ thuá»™c thÆ° viá»‡n ngoÃ i (Zero Dependency):** XÃ¢y dá»±ng hoÃ n toÃ n báº±ng `dart:io` vÃ  `dart:convert`, tÆ°Æ¡ng thÃ­ch 100% vá»›i má»i ná»n táº£ng Flutter/Dart.
5. **Kháº£ nÄƒng chá»‹u lá»—i cao:** Báº¯t trá»n váº¹n ngoáº¡i lá»‡ Timeout (5 giÃ¢y), máº¥t máº¡ng Internet (SocketException), tráº£ vá» Ä‘á»‘i tÆ°á»£ng `TranslationResult` an toÃ n, chá»‘ng crash á»©ng dá»¥ng.

## 3. Cáº¥u trÃºc thÆ° má»¥c mÃ£ nguá»“n

```text
nhom09-65ktpm/
â”œâ”€â”€ docs/
â”‚   â””â”€â”€ HUONG_DAN_SU_DUNG_TRANSLATION_API.md  # TÃ i liá»‡u ká»¹ thuáº­t
â””â”€â”€ src/
    â”œâ”€â”€ lib/
    â”‚   â””â”€â”€ features/
    â”‚       â””â”€â”€ chat_online/
    â”‚           â”œâ”€â”€ models/
    â”‚           â”‚   â””â”€â”€ translation_result.dart # Model káº¿t quáº£ dá»‹ch & CSDL
    â”‚           â””â”€â”€ services/
    â”‚               â””â”€â”€ translation_service.dart # Service gá»i API dá»‹ch
    â””â”€â”€ test/
        â””â”€â”€ translation_service_test.dart       # Kiá»ƒm thá»­ Ä‘á»™c láº­p
```

## 4. HÆ°á»›ng dáº«n tÃ­ch há»£p vÃ o Giao diá»‡n Chat (UI)

DÃ nh cho thÃ nh viÃªn phá»¥ trÃ¡ch giao diá»‡n Chat (Äá»— Viá»‡t Tiáº¿n):

```dart
import 'package:nhom9_65ktpm/features/chat_online/services/translation_service.dart';
import 'package:nhom9_65ktpm/features/chat_online/models/translation_result.dart';

// 1. Khá»Ÿi táº¡o service (Singleton dÃ¹ng chung)
final translationService = TranslationService();

// 2. Gá»i dá»‹ch cÃ¢u chat khi báº¥m nÃºt icon Dá»‹ch
void onTranslateButtonPressed(String messageContent) async {
  final TranslationResult result = await translationService.translateEnToVi(messageContent);

  if (result.isSuccess) {
    print('CÃ¢u dá»‹ch: ${result.translatedText}');
    // setState() Ä‘á»ƒ hiá»ƒn thá»‹ báº£n dá»‹ch ngay dÆ°á»›i bong bÃ³ng chat
  } else {
    // Hiá»ƒn thá»‹ SnackBar thÃ´ng bÃ¡o: result.errorMessage
  }
}
```

