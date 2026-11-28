import '../models/topic_model.dart';

final DateTime _beginnerSeedTime = DateTime(2026, 1, 1);

/// Danh sách chủ đề & kịch bản hội thoại mẫu trình độ sơ cấp (A1 - A2).
final List<TopicModel> defaultBeginnerTopics = [
  // ============================ CẤP ĐỘ A1 ============================
  TopicModel(
    id: 'topic_001',
    title: 'Giới thiệu bản thân',
    titleEn: 'Self Introduction',
    level: 'A1',
    category: 'Daily Life',
    description:
        'Học cách giới thiệu tên, tuổi, quê quán, ngành học và chào hỏi lịch sự.',
    descriptionEn:
        'Learn how to introduce your name, hometown, major, and greet politely.',
    thumbnailIcon: '👋',
    estimatedMinutes: 15,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "Hi! I'm Minh, nice to meet you. Where are you from?",
        textVi: 'Chào bạn! Mình là Minh, rất vui được gặp bạn. Bạn đến từ đâu?',
        tip: 'Mở đầu thân thiện khi gặp bạn học mới trong phòng chat.',
      ),
      ConversationStarter(
        textEn: "What do you study or do for a living?",
        textVi: 'Bạn đang học ngành gì hoặc làm công việc gì?',
        tip: 'Hỏi về nghề nghiệp/ngành học để kéo dài cuộc trò chuyện.',
      ),
      ConversationStarter(
        textEn: "How long have you been practicing English?",
        textVi: 'Bạn đã luyện nói tiếng Anh được bao lâu rồi?',
        tip: 'Câu hỏi tự nhiên để tìm điểm chung trong học tập.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Student',
        textEn: "Hi! My name is Lan. I'm a university student from Hanoi.",
        textVi: 'Chào bạn! Mình tên là Lan. Mình là sinh viên đại học ở Hà Nội.',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Buddy',
        textEn: "Nice to meet you, Lan! I'm Alex from Australia. What is your major?",
        textVi: 'Rất vui được gặp bạn, Lan! Mình là Alex đến từ Úc. Ngành học của bạn là gì?',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Student',
        textEn: "I study Software Engineering. I want to improve my English speaking skills.",
        textVi: 'Mình học Kỹ thuật phần mềm. Mình muốn cải thiện kỹ năng nói tiếng Anh.',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Buddy',
        textEn: "That's awesome! Let's practice together every day.",
        textVi: 'Tuyệt quá! Hãy cùng luyện tập với nhau mỗi ngày nhé.',
      ),
    ],
  ),
  TopicModel(
    id: 'topic_002',
    title: 'Sở thích và thời gian rảnh',
    titleEn: 'Hobbies & Free Time',
    level: 'A1',
    category: 'Daily Life',
    description:
        'Chia sẻ về sở thích cá nhân, âm nhạc, thể thao và kế hoạch cuối tuần.',
    descriptionEn:
        'Share your hobbies, favorite music, sports, and weekend plans.',
    thumbnailIcon: '🎨',
    estimatedMinutes: 15,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "What do you usually do in your free time?",
        textVi: 'Bạn thường làm gì vào thời gian rảnh?',
        tip: 'Câu hỏi cơ bản và dễ trả lời nhất cho trình độ A1.',
      ),
      ConversationStarter(
        textEn: "Do you have any plans for this weekend?",
        textVi: 'Bạn có kế hoạch gì cho cuối tuần này chưa?',
        tip: 'Dùng vào thứ Năm/thứ Sáu để bắt chuyện tự nhiên.',
      ),
      ConversationStarter(
        textEn: "What kind of music or movies do you enjoy?",
        textVi: 'Bạn thích thể loại âm nhạc hay phim ảnh nào?',
        tip: 'Giúp mở rộng sang các chủ đề giải trí quen thuộc.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Friend 1',
        textEn: "Hey, what do you like doing on weekends?",
        textVi: 'Này, bạn thích làm gì vào cuối tuần?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Friend 2',
        textEn: "I love playing badminton and watching sci-fi movies. How about you?",
        textVi: 'Mình thích chơi cầu lông và xem phim khoa học viễn tưởng. Còn bạn thì sao?',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Friend 1',
        textEn: "I usually read books at a quiet coffee shop or listen to podcasts.",
        textVi: 'Mình thường đọc sách ở một quán cà phê yên tĩnh hoặc nghe podcast.',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Friend 2',
        textEn: "Sounds relaxing! Can you recommend a good English podcast?",
        textVi: 'Nghe thư giãn thật! Bạn có thể gợi ý một podcast tiếng Anh hay không?',
      ),
    ],
  ),
  TopicModel(
    id: 'topic_009',
    title: 'Mua sắm & hỏi giá cả',
    titleEn: 'Shopping & Asking Prices',
    level: 'A1',
    category: 'Daily Life',
    description:
        'Thực hành hỏi giá, chọn kích cỡ, màu sắc và thanh toán tại cửa hàng.',
    descriptionEn:
        'Practice asking prices, choosing sizes and colors, and paying at a shop.',
    thumbnailIcon: '🛍️',
    estimatedMinutes: 15,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "Excuse me, how much is this jacket?",
        textVi: 'Xin lỗi, chiếc áo khoác này giá bao nhiêu vậy?',
        tip: 'Mẫu câu hỏi giá ngắn gọn, dễ nhớ cho mọi cửa hàng.',
      ),
      ConversationStarter(
        textEn: "Do you have this shirt in a medium size?",
        textVi: 'Cửa hàng có mẫu áo này cỡ M không?',
        tip: 'Thay "medium" bằng small / large tùy nhu cầu.',
      ),
      ConversationStarter(
        textEn: "Can I try this on over there?",
        textVi: 'Mình có thể mặc thử món này ở đằng kia không?',
        tip: 'Dùng cụm "try ... on" khi muốn thử quần áo.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Shopkeeper',
        textEn: "Hello! Can I help you find anything today?",
        textVi: 'Xin chào! Hôm nay mình có thể giúp bạn tìm món gì không?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Customer',
        textEn: "Yes, I'm looking for a backpack for school. How much is this blue one?",
        textVi: 'Có ạ, mình đang tìm ba lô đi học. Chiếc màu xanh này giá bao nhiêu?',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Shopkeeper',
        textEn: "It's twenty-five dollars, and it's waterproof too.",
        textVi: 'Giá 25 đô la và nó còn chống nước nữa.',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Customer',
        textEn: "Great, I'll take it! Can I pay by card?",
        textVi: 'Tuyệt, mình lấy chiếc này! Mình trả bằng thẻ được không?',
      ),
    ],
  ),

  // ============================ CẤP ĐỘ A2 ============================
  TopicModel(
    id: 'topic_003',
    title: 'Du lịch và hỏi đường',
    titleEn: 'Travel & Directions',
    level: 'A2',
    category: 'Travel',
    description:
        'Thực hành đặt phòng khách sạn, hỏi đường đến địa điểm du lịch và đi phương tiện công cộng.',
    descriptionEn:
        'Practice asking for directions, booking rooms, and using public transport.',
    thumbnailIcon: '✈️',
    estimatedMinutes: 20,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "Excuse me, could you tell me how to get to the nearest train station?",
        textVi: 'Xin lỗi, bạn có thể chỉ cho mình đường đến ga tàu gần nhất không?',
        tip: 'Dùng "Excuse me, could you..." để hỏi đường lịch sự.',
      ),
      ConversationStarter(
        textEn: "What is the most memorable trip you have ever taken?",
        textVi: 'Chuyến du lịch đáng nhớ nhất bạn từng đi là gì?',
        tip: 'Luyện dùng thì hiện tại hoàn thành đơn giản ở mức A2.',
      ),
      ConversationStarter(
        textEn: "Do you prefer traveling to the mountains or the beach?",
        textVi: 'Bạn thích đi du lịch lên núi hay ra biển hơn?',
        tip: 'Câu hỏi lựa chọn giúp đối phương dễ nêu lý do.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Tourist',
        textEn: "Excuse me! Is the Old Quarter far from here?",
        textVi: 'Xin lỗi! Khu Phố Cổ có xa đây không ạ?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Local',
        textEn: "Not really. Just walk straight for two blocks, then turn left at the traffic light.",
        textVi: 'Không xa lắm đâu. Bạn cứ đi thẳng hai dãy nhà, rồi rẽ trái ở đèn giao thông.',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Tourist',
        textEn: "Thank you so much! How long does it take on foot?",
        textVi: 'Cảm ơn bạn nhiều! Đi bộ mất khoảng bao lâu ạ?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Local',
        textEn: "About ten minutes. You'll see lots of street food stalls along the way.",
        textVi: 'Khoảng mười phút. Bạn sẽ thấy rất nhiều quầy đồ ăn đường phố dọc đường.',
      ),
    ],
  ),
  TopicModel(
    id: 'topic_004',
    title: 'Gọi món tại quán cà phê & nhà hàng',
    titleEn: 'Ordering at a Cafe & Restaurant',
    level: 'A2',
    category: 'Food & Drink',
    description:
        'Luyện cách gọi đồ uống, hỏi thành phần món ăn, yêu cầu ít đường/đá và thanh toán.',
    descriptionEn:
        'Practice ordering drinks, asking about ingredients, and asking for the bill.',
    thumbnailIcon: '☕',
    estimatedMinutes: 15,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "Could I have an iced latte with less sugar, please?",
        textVi: 'Cho mình một ly latte đá ít đường nhé?',
        tip: 'Mẫu câu "Could I have..." tự nhiên hơn "I want...".',
      ),
      ConversationStarter(
        textEn: "What dish would you recommend for a first-time visitor?",
        textVi: 'Bạn gợi ý món nào cho người lần đầu đến quán?',
        tip: 'Rất hữu ích khi đi ăn ở nhà hàng địa phương.',
      ),
      ConversationStarter(
        textEn: "Excuse me, could we get the check when you have a moment?",
        textVi: 'Xin lỗi, cho chúng mình xin hóa đơn khi bạn rảnh nhé?',
        tip: 'Cách gọi tính tiền lịch sự tại nhà hàng.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Barista',
        textEn: "Welcome! What can I get started for you today?",
        textVi: 'Chào mừng bạn! Hôm nay bạn muốn gọi gì ạ?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Customer',
        textEn: "Hi, I'd like a medium iced americano and a croissant, please.",
        textVi: 'Chào bạn, cho mình một ly americano đá cỡ vừa và một bánh sừng bò nhé.',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Barista',
        textEn: "Sure thing! Would you like that for here or to go?",
        textVi: 'Được ngay ạ! Bạn dùng tại quán hay mang đi ạ?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Customer',
        textEn: "For here, please. Do you accept card payment?",
        textVi: 'Mình dùng tại quán nhé. Quán có nhận thanh toán thẻ không?',
      ),
    ],
  ),
  TopicModel(
    id: 'topic_010',
    title: 'Khám sức khỏe & hiệu thuốc',
    titleEn: 'At the Clinic & Pharmacy',
    level: 'A2',
    category: 'Health',
    description:
        'Mô tả triệu chứng cảm cúm, đau họng, hỏi liều dùng thuốc và lời khuyên nghỉ ngơi.',
    descriptionEn:
        'Describe common symptoms like a cold or sore throat and ask for dosage advice.',
    thumbnailIcon: '🩺',
    estimatedMinutes: 15,
    createdAt: _beginnerSeedTime,
    conversationStarters: const [
      ConversationStarter(
        textEn: "I've had a sore throat and a mild fever since yesterday.",
        textVi: 'Mình bị đau họng và sốt nhẹ từ hôm qua đến giờ.',
        tip: 'Dùng thì hiện tại hoàn thành với "since" để nói triệu chứng kéo dài.',
      ),
      ConversationStarter(
        textEn: "How many times a day should I take this medicine?",
        textVi: 'Mình nên uống loại thuốc này mấy lần một ngày?',
        tip: 'Câu hỏi thiết yếu khi mua thuốc tại hiệu thuốc.',
      ),
      ConversationStarter(
        textEn: "Should I take it before or after meals?",
        textVi: 'Mình nên uống trước hay sau bữa ăn ạ?',
        tip: 'Ngắn gọn, rõ ràng khi trao đổi với dược sĩ.',
      ),
    ],
    sampleDialogues: const [
      SampleDialogueLine(
        speaker: 'A',
        role: 'Pharmacist',
        textEn: "Hello, how can I help you today?",
        textVi: 'Xin chào, hôm nay mình có thể giúp gì cho bạn?',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Patient',
        textEn: "Hi, I have a runny nose and a headache. Do you have something for a cold?",
        textVi: 'Chào bạn, mình bị sổ mũi và đau đầu. Bạn có thuốc trị cảm lạnh không?',
      ),
      SampleDialogueLine(
        speaker: 'A',
        role: 'Pharmacist',
        textEn: "Yes, these tablets will help. Take one tablet after meals, twice a day.",
        textVi: 'Có ạ, viên này sẽ giúp đỡ. Bạn uống một viên sau ăn, ngày hai lần nhé.',
      ),
      SampleDialogueLine(
        speaker: 'B',
        role: 'Patient',
        textEn: "Got it, thank you! Will it make me feel sleepy?",
        textVi: 'Mình hiểu rồi, cảm ơn bạn! Thuốc này có gây buồn ngủ không ạ?',
      ),
    ],
  ),
];

