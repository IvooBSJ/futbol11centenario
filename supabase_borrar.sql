-- Nadie puede BORRAR un jugador cargado. Solo el dueño puede EDITARLO.
create or replace function public.set_owner() returns trigger language plpgsql as $$
declare h text := encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-owner',''), 'utf8')), 'hex');
begin
  -- Bloquear borrado de jugadores
  if old.name is not null and old.name != '' and (new.name is null or trim(new.name) = '') then
    return null;
  end if;

  if old.owner is null or old.name is null or old.name = '' then
    new.owner := h;
  elsif old.owner = h then
    new.owner := h;
  else
    return null;                    -- editar slot ajeno: se ignora
  end if;
  return new;
end $$;

drop policy if exists "editar" on public.players;
create policy "editar" on public.players for update to anon using (true) with check (true);
