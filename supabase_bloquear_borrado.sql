-- ============================================================
-- BLOQUEAR BORRADO DE JUGADORES EN SUPABASE
-- Ejecutar este script en el SQL Editor de Supabase:
-- 1. Impide que cualquier persona borre un jugador ya cargado.
-- 2. Solo el dueño original (quien lo anotó) puede editar su propio nombre o foto.
-- ============================================================

create or replace function public.set_owner() returns trigger language plpgsql as $$
declare 
  h text := encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-owner',''), 'utf8')), 'hex');
begin
  -- 1. Si el casillero ya tenía un jugador (old.name no está vacío) y se intenta vaciar (borrar), SE RECHAZA
  if old.name is not null and old.name != '' and (new.name is null or trim(new.name) = '') then
    return null; -- Bloquea el borrado
  end if;

  -- 2. Si el casillero estaba libre, quien lo anota pasa a ser el dueño
  if old.owner is null or old.name is null or old.name = '' then
    new.owner := h;
  -- 3. Si ya tenía dueño, solo ese mismo dueño puede actualizar sus datos (nombre/foto)
  elsif old.owner = h then
    new.owner := h;
  else
    -- Intento de modificación por otra persona: se ignora
    return null;
  end if;

  return new;
end $$;

drop trigger if exists t_owner on public.players;
create trigger t_owner before update on public.players for each row execute function public.set_owner();

drop policy if exists "editar" on public.players;
create policy "editar" on public.players for update to anon using (true) with check (true);
