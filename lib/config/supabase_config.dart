import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ⚠️ استبدل القيم أدناه بالقيم من مشروعك في Supabase
  static const String supabaseUrl = 'https://xahqsmyrnnchszqqoqoy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhaHFzbXlybm5jaHN6cXFvcW95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4ODUzMzMsImV4cCI6MjA5MjQ2MTMzM30.BMYg2JHqZKIMfCErbEthNPUtWnzLmWxqX41wkxxbtCY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}