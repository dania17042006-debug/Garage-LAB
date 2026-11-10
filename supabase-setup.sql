-- GARAGE: налаштування бази Supabase. Вставте цей файл ЦІЛИМ у SQL Editor і натисніть Run.
-- Можна запускати повторно: нічого не зламається.

-- 1) Дані користувачів. Кожен бачить і змінює ТІЛЬКИ свої рядки (Row Level Security).
create table if not exists public.kv (
  user_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);
alter table public.kv enable row level security;
drop policy if exists "kv own rows" on public.kv;
create policy "kv own rows" on public.kv for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 2) Відгуки від друзів. Користувачі можуть лише ДОДАВАТИ; читаєте ви в панелі (Table Editor -> feedback).
create table if not exists public.feedback (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  message text not null check (char_length(message) <= 4000),
  meta jsonb,
  created_at timestamptz not null default now()
);
alter table public.feedback enable row level security;
drop policy if exists "feedback insert own" on public.feedback;
create policy "feedback insert own" on public.feedback for insert to authenticated
  with check (auth.uid() = user_id);

-- 3) Приватне сховище фото: кожен працює лише зі своєю папкою.
insert into storage.buckets (id, name, public) values ('photos', 'photos', false) on conflict (id) do nothing;
drop policy if exists "photos read own" on storage.objects;
drop policy if exists "photos insert own" on storage.objects;
drop policy if exists "photos update own" on storage.objects;
drop policy if exists "photos delete own" on storage.objects;
create policy "photos read own" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos insert own" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos update own" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4) «Видалити акаунт»: людина може стерти себе й усі свої дані (фото прибирає сам застосунок перед цим).
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  delete from public.kv where user_id = auth.uid();
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
