import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = 'https://ohlpcdpnweyezmaumfoh.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9obHBjZHBud2V5ZXptYXVtZm9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMDU4ODksImV4cCI6MjA5MTg4MTg4OX0.dKca0h6cKpi68ZZrfjR1_Q4xY2z3_qBRgLtPtqOIUHo';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
  static SupabaseClient get client => Supabase.instance.client;
}
