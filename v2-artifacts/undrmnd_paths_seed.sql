-- undrmnd v2 paths graph seed — run AFTER undrmnd_content_seed_v2.sql (needs content_item rows).
-- Editorial: flip is_featured / is_active in Supabase to taste. Paths are active so get_path(slug) works in dev.

begin;

insert into paths (id, slug, title, subtitle, topic, is_active, is_featured) values
  ('10000000-0000-4000-8000-000000000001', 'first-exploration', 'Your first exploration', 'A short first path', 'cosmos', true, true),
  ('20000000-0000-4000-8000-000000000001', 'the-eighty-five-percent', 'The 85 percent', 'Most of the universe is in the dark', 'cosmos', true, false),
  ('30000000-0000-4000-8000-000000000001', 'the-hard-part', 'The hard part', 'What replication asks of us', 'how_we_know', true, false),
  ('40000000-0000-4000-8000-000000000001', 'what-lives-here', 'What lives here', 'A living-world way in', 'living_world', true, false);

-- Path 1: card → endpoint
insert into path_nodes (id, path_id, node_type, content_item_id, branch_prompt, branch_compass, endpoint_note, map_x, map_y, contributed_by) values
  (
    '10000000-0000-4000-8000-000000000101',
    '10000000-0000-4000-8000-000000000001',
    'card',
    (select id from content_items where title = 'What is dark matter, really?' limit 1),
    null,
    null,
    null,
    0,
    0,
    'teo_ok'
  ),
  (
    '10000000-0000-4000-8000-000000000102',
    '10000000-0000-4000-8000-000000000001',
    'endpoint',
    null,
    null,
    null,
    'That''s a full first exploration. Open the map anytime to see the shape of what you saw.',
    0,
    1,
    null
  );

insert into path_edges (path_id, from_node_id, to_node_id, choice_label, choice_preview, order_index) values
  (
    '10000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000101',
    '10000000-0000-4000-8000-000000000102',
    null,
    null,
    0
  );

-- Path 2: branch → two cards → shared endpoint
insert into path_nodes (id, path_id, node_type, content_item_id, branch_prompt, branch_compass, endpoint_note, map_x, map_y, contributed_by) values
  (
    '20000000-0000-4000-8000-000000000201',
    '20000000-0000-4000-8000-000000000001',
    'branch',
    null,
    'What pulls you in first?',
    'No wrong door.',
    null,
    0,
    0,
    null
  ),
  (
    '20000000-0000-4000-8000-000000000202',
    '20000000-0000-4000-8000-000000000001',
    'card',
    (select id from content_items where title = 'What is dark matter, really?' limit 1),
    null,
    null,
    null,
    -1,
    1,
    'teo_ok'
  ),
  (
    '20000000-0000-4000-8000-000000000203',
    '20000000-0000-4000-8000-000000000001',
    'card',
    (select id from content_items where title = 'Is there a Planet Nine hiding in our own solar system?' limit 1),
    null,
    null,
    null,
    1,
    1,
    'teo_ok'
  ),
  (
    '20000000-0000-4000-8000-000000000204',
    '20000000-0000-4000-8000-000000000001',
    'endpoint',
    null,
    null,
    null,
    'You can reopen the map and take the other branch whenever you like.',
    0,
    2,
    null
  );

insert into path_edges (path_id, from_node_id, to_node_id, choice_label, choice_preview, order_index) values
  (
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000201',
    '20000000-0000-4000-8000-000000000202',
    'The invisible majority',
    'Dark matter, rotation curves, 85% of matter',
    0
  ),
  (
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000201',
    '20000000-0000-4000-8000-000000000203',
    'Closer to home',
    'Planet Nine, orbits, night sky',
    1
  ),
  (
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000202',
    '20000000-0000-4000-8000-000000000204',
    null,
    null,
    0
  ),
  (
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000203',
    '20000000-0000-4000-8000-000000000204',
    null,
    null,
    0
  );

-- Path 3: single card line (replication) → endpoint
insert into path_nodes (id, path_id, node_type, content_item_id, branch_prompt, branch_compass, endpoint_note, map_x, map_y, contributed_by) values
  (
    '30000000-0000-4000-8000-000000000301',
    '30000000-0000-4000-8000-000000000001',
    'card',
    (select id from content_items where title = 'Why is the replication crisis not a scandal?' limit 1),
    null,
    null,
    null,
    0,
    0,
    'ilhan_b'
  ),
  (
    '30000000-0000-4000-8000-000000000302',
    '30000000-0000-4000-8000-000000000001',
    'endpoint',
    null,
    null,
    null,
    'Hard questions stay open. That''s the work.',
    0,
    1,
    null
  );

insert into path_edges (path_id, from_node_id, to_node_id, choice_label, choice_preview, order_index) values
  (
    '30000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000301',
    '30000000-0000-4000-8000-000000000302',
    null,
    null,
    0
  );

-- Path 4: living world card → endpoint
insert into path_nodes (id, path_id, node_type, content_item_id, branch_prompt, branch_compass, endpoint_note, map_x, map_y, contributed_by) values
  (
    '40000000-0000-4000-8000-000000000401',
    '40000000-0000-4000-8000-000000000001',
    'card',
    (select id from content_items where title = 'How many species share Earth with us? No one knows within a factor of 10.' limit 1),
    null,
    null,
    null,
    0,
    0,
    'sage_m'
  ),
  (
    '40000000-0000-4000-8000-000000000402',
    '40000000-0000-4000-8000-000000000001',
    'endpoint',
    null,
    null,
    null,
    'The room stays open. Nothing here asks you to keep scrolling.',
    0,
    1,
    null
  );

insert into path_edges (path_id, from_node_id, to_node_id, choice_label, choice_preview, order_index) values
  (
    '40000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000401',
    '40000000-0000-4000-8000-000000000402',
    null,
    null,
    0
  );

commit;
