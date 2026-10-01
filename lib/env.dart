/// Supabase project connection details.
///
/// The anon/publishable key is safe to ship in client code: it identifies
/// the project, not a privileged user, and every table it can touch is
/// locked down by row-level security policies on the database itself.
class SupabaseEnv {
  const SupabaseEnv._();

  static const String url = 'https://tzmjtbemafzsdlstwmgg.supabase.co';
  static const String anonKey =
      'sb_publishable_CmjdNaSws-mcMhPGbILYBA_FGFgE5wh';

  /// Private storage bucket holding uploaded floor plan images.
  static const String floorPlansBucket = 'floorplans';
}
