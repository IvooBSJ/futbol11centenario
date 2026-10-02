-- Permite nombres de hasta 20 caracteres
alter table public.players drop constraint if exists players_name_check;
alter table public.players add constraint players_name_check check (char_length(name) <= 20);
