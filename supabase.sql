create table if not exists public.players (
  team int not null check (team in (0,1)),
  pos int not null check (pos between 0 and 10),
  name text not null default '' check (char_length(name) <= 12),
  photo text,
  updated_at timestamptz default now(),
  primary key (team, pos)
);
insert into public.players (team, pos)
select t, p from generate_series(0,1) t, generate_series(0,10) p
on conflict do nothing;

alter table public.players enable row level security;
create policy "leer" on public.players for select to anon using (true);
create policy "editar" on public.players for update to anon using (true) with check (true);
grant select, update on public.players to anon;

alter publication supabase_realtime add table public.players;

insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true) on conflict do nothing;
create policy "fotos leer" on storage.objects for select to anon using (bucket_id = 'fotos');
create policy "fotos subir" on storage.objects for insert to anon with check (bucket_id = 'fotos');
