import '../models/topic_model.dart';

/// Dữ liệu kịch bản hội thoại & gợi ý câu mở đầu chuẩn theo 4 cấp độ CEFR (A1 - B2).
/// Dùng làm nguồn bổ sung cho các dòng seed cơ bản trên Supabase và fallback khi offline.
class DefaultTopicsData {
  DefaultTopicsData._();

  static final DateTime _seedTime = DateTime(2026, 1, 1);

  static final List<TopicModel> topics = [
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
      createdAt: _seedTime,
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
      createdAt: _seedTime,
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
      createdAt: _seedTime,
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
      createdAt: _seedTime,
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

    // ============================ CẤP ĐỘ B1 ============================
    TopicModel(
      id: 'topic_005',
      title: 'Phỏng vấn xin việc thực tập IT',
      titleEn: 'Tech Internship Interview',
      level: 'B1',
      category: 'Career',
      description:
          'Trả lời câu hỏi phỏng vấn về dự án cá nhân, điểm mạnh/điểm yếu và làm việc nhóm.',
      descriptionEn:
          'Answer interview questions about projects, strengths, and teamwork.',
      thumbnailIcon: '💼',
      estimatedMinutes: 25,
      createdAt: _seedTime,
      conversationStarters: const [
        ConversationStarter(
          textEn: "Could you walk me through a project you are most proud of?",
          textVi: 'Bạn có thể giới thiệu về một dự án mà bạn tự hào nhất không?',
          tip: 'Trả lời theo cấu trúc: Bối cảnh -> Vai trò -> Kết quả.',
        ),
        ConversationStarter(
          textEn: "How do you usually handle tight deadlines in a team project?",
          textVi: 'Bạn thường xử lý thế nào khi dự án nhóm có deadline gấp?',
          tip: 'Nhấn mạnh kỹ năng giao tiếp và chia nhỏ công việc.',
        ),
        ConversationStarter(
          textEn: "What motivates you to apply for this internship role?",
          textVi: 'Điều gì thúc đẩy bạn ứng tuyển vào vị trí thực tập này?',
          tip: 'Kết nối mục tiêu học hỏi của bạn với sản phẩm công ty.',
        ),
      ],
      sampleDialogues: const [
        SampleDialogueLine(
          speaker: 'A',
          role: 'Interviewer',
          textEn: "Thanks for joining today. Can you briefly describe your recent mobile app project?",
          textVi: 'Cảm ơn bạn đã tham gia hôm nay. Bạn có thể mô tả ngắn về dự án app di động gần đây không?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Candidate',
          textEn: "Certainly! My team built BuddyTalk using Flutter and Supabase to help students practice speaking daily.",
          textVi: 'Chắc chắn rồi ạ! Nhóm em xây dựng BuddyTalk bằng Flutter và Supabase để giúp sinh viên luyện nói mỗi ngày.',
        ),
        SampleDialogueLine(
          speaker: 'A',
          role: 'Interviewer',
          textEn: "Interesting! What was the biggest challenge you faced during development?",
          textVi: 'Thú vị đấy! Thử thách lớn nhất bạn gặp trong quá trình phát triển là gì?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Candidate',
          textEn: "Keeping state clean across screens was tricky, so we adopted Provider and separated data layers clearly.",
          textVi: 'Giữ state gọn gàng giữa các màn hình khá khó, nên bọn em áp dụng Provider và tách rõ tầng dữ liệu.',
        ),
      ],
    ),
    TopicModel(
      id: 'topic_006',
      title: 'Quản lý thời gian & kỷ luật học tập',
      titleEn: 'Time Management & Study Habits',
      level: 'B1',
      category: 'Self Improvement',
      description:
          'Thảo luận về phương pháp giữ chuỗi học tập (streak), tránh trì hoãn và cân bằng cuộc sống.',
      descriptionEn:
          'Discuss staying consistent, avoiding procrastination, and balancing study with rest.',
      thumbnailIcon: '⏱️',
      estimatedMinutes: 20,
      createdAt: _seedTime,
      conversationStarters: const [
        ConversationStarter(
          textEn: "What helps you stay consistent when you don't feel motivated?",
          textVi: 'Điều gì giúp bạn duy trì đều đặn khi không có động lực?',
          tip: 'Chủ đề rất hợp để bàn về thói quen nhỏ mỗi ngày.',
        ),
        ConversationStarter(
          textEn: "Have you ever tried the Pomodoro technique for studying?",
          textVi: 'Bạn đã bao giờ thử phương pháp Pomodoro khi học chưa?',
          tip: 'Gợi mở trao đổi kinh nghiệm học tập thực tế.',
        ),
        ConversationStarter(
          textEn: "What is your biggest distraction when working from home?",
          textVi: 'Yếu tố gây xao nhãng lớn nhất của bạn khi học/làm tại nhà là gì?',
          tip: 'Tạo sự đồng cảm và dễ bàn giải pháp.',
        ),
      ],
      sampleDialogues: const [
        SampleDialogueLine(
          speaker: 'A',
          role: 'Learner',
          textEn: "I keep procrastinating on my English speaking practice. How do you stay disciplined?",
          textVi: 'Mình cứ hay trì hoãn việc luyện nói tiếng Anh. Làm sao bạn giữ được kỷ luật vậy?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Mentor',
          textEn: "I set a tiny goal of just 15 minutes right after dinner so it never feels overwhelming.",
          textVi: 'Mình đặt mục tiêu nhỏ chỉ 15 phút ngay sau bữa tối để không bao giờ cảm thấy quá tải.',
        ),
        SampleDialogueLine(
          speaker: 'A',
          role: 'Learner',
          textEn: "That makes sense. Do you practice alone or with a speaking partner?",
          textVi: 'Nghe hợp lý đấy. Bạn luyện một mình hay với bạn đồng hành?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Mentor',
          textEn: "Having a study buddy makes a huge difference because you hold each other accountable.",
          textVi: 'Có bạn học cùng tạo ra khác biệt rất lớn vì hai người cùng nhắc nhở trách nhiệm cho nhau.',
        ),
      ],
    ),

    // ============================ CẤP ĐỘ B2 ============================
    TopicModel(
      id: 'topic_007',
      title: 'Tác động của AI đến việc học & nghề nghiệp',
      titleEn: 'Impact of AI on Learning & Careers',
      level: 'B2',
      category: 'Technology',
      description:
          'Tranh luận đa chiều về cơ hội và thách thức của trí tuệ nhân tạo đối với sinh viên và kỹ sư.',
      descriptionEn:
          'Debate the opportunities and challenges of AI for students and software engineers.',
      thumbnailIcon: '🤖',
      estimatedMinutes: 25,
      createdAt: _seedTime,
      conversationStarters: const [
        ConversationStarter(
          textEn: "To what extent do you think AI tools help or hinder language learners?",
          textVi: 'Bạn nghĩ công cụ AI hỗ trợ hay cản trở người học ngôn ngữ ở mức độ nào?',
          tip: 'Dùng "To what extent..." để mở đầu thảo luận học thuật B2.',
        ),
        ConversationStarter(
          textEn: "Which human skills will remain irreplaceable despite rapid automation?",
          textVi: 'Những kỹ năng nào của con người sẽ không thể thay thế dù tự động hóa phát triển nhanh?',
          tip: 'Khuyến khích đối phương phân tích sâu và đưa ví dụ.',
        ),
        ConversationStarter(
          textEn: "How should universities adapt their curriculum in the age of generative AI?",
          textVi: 'Các trường đại học nên điều chỉnh chương trình học thế nào trong kỷ nguyên AI tạo sinh?',
          tip: 'Luyện cấu trúc đưa ra đề xuất (should / ought to / in my view).',
        ),
      ],
      sampleDialogues: const [
        SampleDialogueLine(
          speaker: 'A',
          role: 'Speaker 1',
          textEn: "While AI can speed up coding and writing, I worry students might rely on it too heavily.",
          textVi: 'Dù AI có thể tăng tốc viết code và viết lách, mình lo sinh viên có thể phụ thuộc vào nó quá mức.',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Speaker 2',
          textEn: "I see your point, yet when used critically, AI acts like a 24/7 personal tutor.",
          textVi: 'Mình hiểu ý bạn, nhưng nếu dùng có tư duy phản biện, AI giống như một gia sư cá nhân 24/7.',
        ),
        SampleDialogueLine(
          speaker: 'A',
          role: 'Speaker 1',
          textEn: "Fair enough. So the key is learning how to verify outputs rather than copying blindly.",
          textVi: 'Cũng đúng. Vậy mấu chốt là học cách kiểm chứng kết quả thay vì sao chép mù quáng.',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Speaker 2',
          textEn: "Exactly—strong fundamentals and clear communication will matter more than ever.",
          textVi: 'Chính xác—nền tảng vững và giao tiếp rõ ràng sẽ quan trọng hơn bao giờ hết.',
        ),
      ],
    ),
    TopicModel(
      id: 'topic_008',
      title: 'Thương lượng & giải quyết bất đồng trong nhóm',
      titleEn: 'Negotiation & Conflict Resolution',
      level: 'B2',
      category: 'Communication',
      description:
          'Luyện cách trình bày quan điểm khéo léo, lắng nghe phản biện và đi đến thống nhất chung.',
      descriptionEn:
          'Practice expressing disagreement diplomatically, active listening, and reaching consensus.',
      thumbnailIcon: '🤝',
      estimatedMinutes: 25,
      createdAt: _seedTime,
      conversationStarters: const [
        ConversationStarter(
          textEn: "I appreciate your perspective, though I wonder if we could explore an alternative.",
          textVi: 'Mình trân trọng góc nhìn của bạn, nhưng liệu chúng ta có thể xem xét một phương án khác không?',
          tip: 'Cách phản biện mềm mỏng, chuyên nghiệp ở cấp độ B2.',
        ),
        ConversationStarter(
          textEn: "What trade-offs are we willing to accept to ship this feature on schedule?",
          textVi: 'Chúng ta sẵn sàng đánh đổi điều gì để ra mắt tính năng này đúng tiến độ?',
          tip: 'Đưa cuộc thảo luận về giải pháp thực tế thay vì tranh cãi.',
        ),
        ConversationStarter(
          textEn: "Could we align on the core priority before diving into implementation details?",
          textVi: 'Chúng ta có thể thống nhất ưu tiên cốt lõi trước khi đi sâu vào chi tiết triển khai không?',
          tip: 'Rất hiệu quả khi họp nhóm hoặc làm việc đa phòng ban.',
        ),
      ],
      sampleDialogues: const [
        SampleDialogueLine(
          speaker: 'A',
          role: 'Lead',
          textEn: "We're running behind schedule. Should we cut some secondary animations for this release?",
          textVi: 'Chúng ta đang chậm tiến độ. Có nên cắt bớt một số hiệu ứng phụ cho bản phát hành này không?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Designer',
          textEn: "I understand the deadline pressure, but smooth transitions really affect first impressions.",
          textVi: 'Mình hiểu áp lực deadline, nhưng chuyển động mượt thực sự ảnh hưởng đến ấn tượng đầu tiên.',
        ),
        SampleDialogueLine(
          speaker: 'A',
          role: 'Lead',
          textEn: "What if we keep the main onboarding transition and defer the secondary ones to next sprint?",
          textVi: 'Thế nếu chúng ta giữ lại hiệu ứng onboarding chính và dời các hiệu ứng phụ sang sprint sau thì sao?',
        ),
        SampleDialogueLine(
          speaker: 'B',
          role: 'Designer',
          textEn: "That sounds like a fair compromise. Let's update the sprint board right away.",
          textVi: 'Nghe như một sự dung hòa hợp lý. Hãy cập nhật bảng sprint ngay nhé.',
        ),
      ],
    ),
  ];

  static Map<String, TopicModel> get byId => {
        for (final topic in topics) topic.id: topic,
      };
}

