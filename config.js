// Впишіть дані зі свого проєкту Supabase (Project Settings -> API).
// Обидва значення ПУБЛІЧНІ за задумом Supabase: від чужого доступу дані захищає база (правила з файлу supabase-setup.sql).
window.GARAGE_CONFIG = {
  supabaseUrl: "ВСТАВТЕ_АДРЕСУ_ПРОЄКТУ",     // виглядає як https://abcdefgh.supabase.co
  supabaseAnonKey: "ВСТАВТЕ_ПУБЛІЧНИЙ_КЛЮЧ"   // довгий ключ (починається з eyJ... або sb_publishable_...)
};
