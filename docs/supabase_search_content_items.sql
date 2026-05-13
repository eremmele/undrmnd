-- undrmnd — text search for spatial map / curiosity entry
-- Run in Supabase SQL Editor (anon must keep SELECT on content_items per your RLS).
--
-- Returns active rows whose title or hook matches the query (ILIKE).
-- Best title match first, then shorter titles for stability.

create or replace function public.search_content_items(search_query text, result_limit int default 12)
returns setof public.content_items
language sql
stable
security invoker
set search_path = public
as $$
  select *
  from public.content_items
  where coalesce(is_active, true) = true
    and length(trim(search_query)) >= 2
    and (
      title ilike '%' || trim(search_query) || '%'
      or hook ilike '%' || trim(search_query) || '%'
    )
  order by
    case
      when lower(trim(title)) = lower(trim(search_query)) then 0
      when lower(trim(title)) like lower(trim(search_query)) || '%' then 1
      when lower(trim(hook)) like lower(trim(search_query)) || '%' then 2
      else 3
    end,
    length(title) asc nulls last
  limit greatest(1, least(coalesce(result_limit, 12), 24));
$$;

grant execute on function public.search_content_items(text, int) to anon, authenticated;
