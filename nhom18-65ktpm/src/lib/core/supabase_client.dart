import 'package:supabase_flutter/supabase_flutter.dart';

/// Một điểm truy cập Supabase duy nhất cho toàn app.
/// `main()` phải gọi `Supabase.initialize` trước khi dùng.
SupabaseClient get supabase => Supabase.instance.client;
