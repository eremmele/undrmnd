-- RPC: create a reply on an active thread (anon-safe via SECURITY DEFINER).
-- Clients with the anon key should use this RPC instead of inserting into contribute_posts directly.

create or replace function public.create_contribute_post(
  p_thread_id uuid,
  p_body text,
  p_author_handle text default 'explorer'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_body text;
  v_handle text;
  v_id uuid;
begin
  v_body := trim(p_body);
  if length(v_body) < 1 or length(v_body) > 6000 then
    raise exception 'invalid_body' using errcode = '22000';
  end if;

  if not exists (
    select 1 from public.contribute_threads t
    where t.id = p_thread_id and t.is_active = true
  ) then
    raise exception 'thread_not_found' using errcode = 'P0002';
  end if;

  v_handle := trim(both '@' from trim(p_author_handle));
  if length(v_handle) < 1 or length(v_handle) > 32 then
    raise exception 'invalid_handle' using errcode = '22000';
  end if;
  if v_handle !~ '^[a-zA-Z0-9_]+$' then
    raise exception 'invalid_handle' using errcode = '22000';
  end if;

  insert into public.contribute_posts (thread_id, body, author_handle, is_opening)
  values (p_thread_id, v_body, v_handle, false)
  returning id into v_id;

  update public.contribute_threads
    set updated_at = now()
  where id = p_thread_id;

  return jsonb_build_object('id', v_id);
end;
$$;

revoke all on function public.create_contribute_post(uuid, text, text) from public;
grant execute on function public.create_contribute_post(uuid, text, text) to anon, authenticated;
