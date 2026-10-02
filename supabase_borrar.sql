-- Cualquiera puede BORRAR el slot de otro; solo el dueño puede EDITARLO.
create or replace function public.set_owner() returns trigger language plpgsql as $$
declare h text := encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-owner',''), 'utf8')), 'hex');
begin
  if new.name = '' then            -- borrar: libre para todos
    new.owner := null;
    new.photo := null;
  elsif old.owner is null or old.owner = h then   -- tomar slot libre / editar el propio
    new.owner := h;
  else
    return null;                    -- editar slot ajeno: se ignora
  end if;
  return new;
end $$;

drop policy if exists "editar" on public.players;
create policy "editar" on public.players for update to anon using (true) with check (true);
