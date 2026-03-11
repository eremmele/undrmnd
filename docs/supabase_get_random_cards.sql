-- Run in Supabase SQL Editor. Returns only the columns the app decodes (id, title, hook, interaction_type).
create or replace function get_random_cards(n int default 3)
returns table (id uuid, title text, hook text, interaction_type text)
language sql
as $$
  select id, title, hook, interaction_type
  from content_items
  where is_active = true
  order by random()
  limit n;
$$;
