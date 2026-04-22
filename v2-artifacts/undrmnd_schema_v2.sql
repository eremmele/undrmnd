-- undrmnd Schema v2 — migrations to run in Supabase SQL Editor
-- Safe to run on top of the existing v1 schema. Idempotent where possible.
--
-- What this does:
--   1. Adds new columns to content_items (is_open_question, action_url, contributed_by)
--   2. Tightens interaction_type to 4 values (read, reflect, observe, contribute)
--   3. Updates get_random_cards to only serve open-question rows
--   4. Creates profiles table (anti-gamification, handle-as-identity)
--   5. Creates paths and path_nodes tables (tree/graph, map-openable)
--   6. Creates events table (external-link-only sourcing, per v1 proposal)
--   7. Row-Level Security policies for public read + authenticated write

begin;

-- ============================================================
-- 1. content_items — new columns + stricter interaction_type
-- ============================================================

alter table content_items
  add column if not exists is_open_question boolean not null default false,
  add column if not exists action_url text,
  add column if not exists contributed_by text;  -- username handle, e.g. 'teo_ok'

-- Backfill contributed_by from legacy created_by if present.
-- (Non-destructive; created_by stays for auth linkage.)
-- Nothing to do here if your v1 created_by was uuid-only.

-- Constrain interaction_type to the 4 values we're keeping.
-- Drop existing check if present, then re-add.
do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_name = 'content_items'
      and constraint_name = 'content_items_interaction_type_check'
  ) then
    alter table content_items drop constraint content_items_interaction_type_check;
  end if;
end$$;

alter table content_items
  add constraint content_items_interaction_type_check
  check (interaction_type in ('read','reflect','observe','contribute'));

-- Pillar enforcement at the schema level.
do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_name = 'content_items'
      and constraint_name = 'content_items_topic_check'
  ) then
    alter table content_items drop constraint content_items_topic_check;
  end if;
end$$;

alter table content_items
  add constraint content_items_topic_check
  check (topic in ('cosmos','living_world','mind_and_brain','how_we_know'));

create index if not exists content_items_open_question_active_idx
  on content_items (topic)
  where is_open_question = true and is_active = true;

-- ============================================================
-- 2. get_random_cards — open-question filter (full content_items row)
-- ============================================================
-- The iOS app decodes a subset as `ContentPreview` (id, title, hook, interaction_type, …).

create or replace function get_random_cards(n int default 3)
returns setof content_items
language sql
stable
as $$
  select * from content_items
  where is_active = true and is_open_question = true
  order by random() limit greatest(1, n);
$$;

-- ============================================================
-- 3. profiles — handle-as-identity, no gamification metrics
-- ============================================================

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique
    check (username ~ '^[a-z0-9_]{2,24}$'),      -- lowercase, digits, underscore; 2–24 chars
  display_name text,
  bio text check (char_length(coalesce(bio,'')) <= 140),  -- one sentence, enforced
  pillars_following text[] not null default array[]::text[],
  contributions_count int not null default 0,    -- cards authored; NOT streak, NOT karma
  is_contributor boolean not null default false, -- flipped true after first approved PR
  joined_at timestamptz not null default now()
);

-- Explicitly NOT on this table: followers, following, xp, level,
-- streak_days, paths_completed, karma, reputation, reactions.
-- Adding any of those is a rubric violation; gate via code review.

create index if not exists profiles_username_idx on profiles (username);

-- ============================================================
-- 4. paths + path_nodes — tree/graph, map-openable
-- ============================================================

create table if not exists paths (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z0-9-]{3,48}$'),
  title text not null,
  subtitle text,                                 -- e.g. "Your first exploration"
  topic text not null
    check (topic in ('cosmos','living_world','mind_and_brain','how_we_know')),
  is_active boolean not null default false,      -- editorial gate
  is_featured boolean not null default false,    -- surfaces on home
  created_at timestamptz not null default now()
);

-- Node types:
--   'card'     — wraps a content_item; renders as a card
--   'branch'   — fork point; has 2–4 child 'card' nodes downstream
--   'endpoint' — optional terminal node with a closing reflection (no outgoing edges)
--
-- Tree/graph structure via parent_id AND an explicit edges table below.
-- parent_id alone is enough for strict trees. We also store 'edges' so a single
-- card can be reached from multiple branches (DAG) — useful when two threads
-- converge on the same open question.

create table if not exists path_nodes (
  id uuid primary key default gen_random_uuid(),
  path_id uuid not null references paths(id) on delete cascade,
  node_type text not null check (node_type in ('card','branch','endpoint')),

  -- For 'card' nodes: the content_item this node renders.
  content_item_id uuid references content_items(id) on delete restrict,

  -- For 'branch' nodes: the question shown at the fork.
  branch_prompt text,            -- e.g. "What catches you?"
  branch_compass text,           -- optional subtext, e.g. "No wrong door."

  -- For 'endpoint' nodes: one closing line, no action buttons.
  endpoint_note text,

  -- Layout hints for the map view. Optional; UI can auto-layout if null.
  map_x int,
  map_y int,

  -- Authorship metadata (per-card byline; lives on the node, not the path).
  contributed_by text,

  created_at timestamptz not null default now(),

  -- Invariants
  constraint path_nodes_card_has_content
    check ((node_type = 'card') = (content_item_id is not null)),
  constraint path_nodes_branch_has_prompt
    check ((node_type = 'branch') = (branch_prompt is not null))
);

create index if not exists path_nodes_path_idx on path_nodes (path_id);

-- Edges — directed. A 'branch' node has 2–4 outgoing edges, each labeled
-- with the choice text the user sees. A 'card' or 'endpoint' node has 0 or 1
-- outgoing edges (linear continuation).
create table if not exists path_edges (
  id uuid primary key default gen_random_uuid(),
  path_id uuid not null references paths(id) on delete cascade,
  from_node_id uuid not null references path_nodes(id) on delete cascade,
  to_node_id uuid not null references path_nodes(id) on delete cascade,
  choice_label text,             -- required when from_node is a 'branch'; null otherwise
  choice_preview text,           -- optional; renders under choice_label, e.g. "WIMPs, axions, neither"
  order_index int not null default 0,
  created_at timestamptz not null default now(),
  constraint path_edges_no_self_loop check (from_node_id <> to_node_id),
  unique (from_node_id, to_node_id)
);

create index if not exists path_edges_path_idx on path_edges (path_id);
create index if not exists path_edges_from_idx on path_edges (from_node_id);

-- Convenience: fetch a full path as JSON for the client (used by the map view).
create or replace function get_path(path_slug text)
returns jsonb
language sql
stable
as $$
  with p as (
    select * from paths where slug = path_slug and is_active = true
  ),
  n as (
    select
      pn.id, pn.node_type, pn.branch_prompt, pn.branch_compass,
      pn.endpoint_note, pn.map_x, pn.map_y, pn.contributed_by,
      to_jsonb(ci) - 'created_at' - 'created_by' as content
    from path_nodes pn
    left join content_items ci on ci.id = pn.content_item_id
    where pn.path_id = (select id from p)
  ),
  e as (
    select from_node_id, to_node_id, choice_label, choice_preview, order_index
    from path_edges where path_id = (select id from p)
  )
  select jsonb_build_object(
    'path', to_jsonb((select row_to_json(p.*) from p)),
    'nodes', coalesce((select jsonb_agg(n.*) from n), '[]'::jsonb),
    'edges', coalesce((select jsonb_agg(e.*) from e), '[]'::jsonb)
  );
$$;

-- ============================================================
-- 5. events — lifted from v1 proposal so everything lives together
-- ============================================================

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text,
  is_online boolean not null default false,
  host text not null,
  host_url text,
  topic text not null
    check (topic in ('cosmos','living_world','mind_and_brain','how_we_know')),
  source_url text not null,
  source_license text not null
    check (source_license in ('public','cc-by','external-link-only')),
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 6. Row-Level Security
-- ============================================================

alter table profiles    enable row level security;
alter table paths       enable row level security;
alter table path_nodes  enable row level security;
alter table path_edges  enable row level security;
alter table events      enable row level security;

-- Public read on everything editorially approved.
drop policy if exists "public read profiles" on profiles;
create policy "public read profiles" on profiles
  for select using (true);

drop policy if exists "public read active paths" on paths;
create policy "public read active paths" on paths
  for select using (is_active = true);

drop policy if exists "public read nodes for active paths" on path_nodes;
create policy "public read nodes for active paths" on path_nodes
  for select using (exists (
    select 1 from paths p where p.id = path_nodes.path_id and p.is_active = true
  ));

drop policy if exists "public read edges for active paths" on path_edges;
create policy "public read edges for active paths" on path_edges
  for select using (exists (
    select 1 from paths p where p.id = path_edges.path_id and p.is_active = true
  ));

drop policy if exists "public read active events" on events;
create policy "public read active events" on events
  for select using (is_active = true);

-- Writes: only authenticated users can edit their own profile; card/path edits
-- go through the PR → reviewer → flip-is_active flow, not direct writes.
drop policy if exists "owner can update profile" on profiles;
create policy "owner can update profile" on profiles
  for update using (auth.uid() = id);

drop policy if exists "owner can insert profile" on profiles;
create policy "owner can insert profile" on profiles
  for insert with check (auth.uid() = id);

commit;
