-- Dueño de cada slot: solo quien lo cargó puede editarlo/borrarlo.
alter table public.players add column if not exists owner text;

create or replace function public.set_owner() returns trigger language plpgsql as $$
begin
  if new.name = '' then
    new.owner := null;
  else
    new.owner := encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-owner',''), 'utf8')), 'hex');
  end if;
  return new;
end $$;

drop trigger if exists t_owner on public.players;
create trigger t_owner before update on public.players for each row execute function public.set_owner();

drop policy if exists "editar" on public.players;
create policy "editar" on public.players for update to anon
  using (owner is null or owner = encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-owner',''), 'utf8')), 'hex'))
  with check (true);

-- los jugadores ya cargados quedan libres: quien los vuelva a guardar pasa a ser su dueño
update public.players set owner = null;
