-- ============================================================================
-- MIGRATION 003: GHÉP CẶP BUDDY & CHAT REALTIME (1-1 VÀ NHÓM HỌC TẬP)
-- Phụ trách: Đỗ Việt Tiến (buddy_matches) & Phạm Văn Hưng (conversations, messages)
--   - N users <-- N:N --> N users (qua buddy_matches)
--   - N users <-- N:N --> N conversations (qua conversation_members)
--   - 1 conversations -- 1:N --> messages
-- ============================================================================

-- 7. BẢNG BUDDY_MATCHES: Lời mời & cặp đôi bạn đồng hành bù trừ ngôn ngữ
CREATE TABLE IF NOT EXISTS public.buddy_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  matched_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT buddy_no_self_match CHECK (requester_id <> receiver_id),
  CONSTRAINT buddy_unique_pair UNIQUE (requester_id, receiver_id)
);

-- 8. BẢNG CONVERSATIONS: Thống nhất cả Chat 1-1 ('direct') & Chat Nhóm học ('group')
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  name TEXT,                                    -- Tên nhóm (null nếu là chat 1-1)
  description TEXT DEFAULT '',
  topic_category TEXT DEFAULT 'Daily Life',
  level TEXT DEFAULT 'A1',                      -- A1, A2, B1, B2
  target_lang TEXT DEFAULT 'en',                -- en, zh, vi
  max_members INTEGER NOT NULL DEFAULT 20,
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  last_message_text TEXT DEFAULT '',
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. BẢNG CONVERSATION_MEMBERS: Bảng trung gian N-N giữa users và conversations
CREATE TABLE IF NOT EXISTS public.conversation_members (
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

-- 10. BẢNG MESSAGES: Tin nhắn Realtime (thuộc đúng 1 conversation_id)
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  translated_content TEXT,
  source_lang TEXT,
  target_lang TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
