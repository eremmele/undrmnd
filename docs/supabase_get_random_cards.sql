-- Standalone snippet: keep in sync with v2-artifacts/undrmnd_schema_v2.sql
create or replace function get_random_cards(n int default 3)
returns setof content_items
language sql stable as $$
  select * from content_items
  where is_active = true and is_open_question = true
  order by random() limit greatest(1, n);
$$;
