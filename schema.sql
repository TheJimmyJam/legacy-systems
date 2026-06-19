-- ============================================================
-- LEGACY SYSTEMS — Supabase schema (all tables prefixed LS_)
-- Account: cannoncodeconnect (azkyohtmhlvnkziuvgvk)
-- Run this whole file in the Supabase SQL editor (web).
-- Safe to re-run: drops + recreates LS_ tables and reseeds.
-- ============================================================

-- ---------- RESET (LS_ only — leaves other projects alone) ----------
drop table if exists "LS_notes"          cascade;
drop table if exists "LS_relationships"  cascade;
drop table if exists "LS_scenes"         cascade;
drop table if exists "LS_systems"        cascade;
drop table if exists "LS_timeline_events" cascade;
drop table if exists "LS_themes"         cascade;
drop table if exists "LS_character_arcs" cascade;
drop table if exists "LS_characters"     cascade;
drop table if exists "LS_factions"       cascade;

-- ---------- FACTIONS ----------
create table "LS_factions" (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  color       text,
  created_at  timestamptz default now()
);

-- ---------- CHARACTERS ----------
create table "LS_characters" (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  full_name       text,
  age             int,
  dob             text,
  birthplace      text,
  role            text,            -- legacy_team / young_engineer / antagonist
  faction_id      uuid references "LS_factions"(id) on delete set null,
  knowledge_domain text,
  casting_ideas   text,
  description     text,
  status          text default 'idea',
  color           text,
  photo_url       text,
  sort_order      int default 0,
  created_at      timestamptz default now()
);

-- ---------- CHARACTER ARCS ----------
create table "LS_character_arcs" (
  id           uuid primary key default gen_random_uuid(),
  character_id uuid references "LS_characters"(id) on delete cascade,
  act          text,
  stage        text,   -- setup/catalyst/midpoint/crisis/resolution
  description  text,
  sort_order   int default 0,
  created_at   timestamptz default now()
);

-- ---------- TIMELINE EVENTS ----------
create table "LS_timeline_events" (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text,
  event_date   text,   -- real date (births/retirements)
  story_time   text,   -- Hour 0, Day 2...
  layer        text,   -- lifetimes / crisis
  act          text,
  type         text,   -- birth/retirement/pushed_out/storm/shutdown/restart_deadline/story_beat
  character_id uuid references "LS_characters"(id) on delete set null,
  system_id    uuid,
  sort_order   int default 0,
  created_at   timestamptz default now()
);

-- ---------- SYSTEMS (The Clock) ----------
create table "LS_systems" (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  countdown_hours      int,
  status               text default 'green',  -- green/amber/red
  assigned_character_id uuid references "LS_characters"(id) on delete set null,
  description          text,
  sort_order           int default 0,
  created_at           timestamptz default now()
);

-- ---------- SCENES (writing surface) ----------
create table "LS_scenes" (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  act          text,
  status       text default 'idea',  -- idea/outlined/drafted/done
  character_ids uuid[] default '{}',
  content      text,
  sort_order   int default 0,
  created_at   timestamptz default now()
);

-- ---------- RELATIONSHIPS ----------
create table "LS_relationships" (
  id                  uuid primary key default gen_random_uuid(),
  source_character_id uuid references "LS_characters"(id) on delete cascade,
  target_character_id uuid references "LS_characters"(id) on delete cascade,
  type                text,   -- mentor/ally/adversary
  label               text,
  created_at          timestamptz default now()
);

-- ---------- THEMES ----------
create table "LS_themes" (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  sort_order  int default 0,
  created_at  timestamptz default now()
);

-- ---------- NOTES (activity log) ----------
create table "LS_notes" (
  id          uuid primary key default gen_random_uuid(),
  entity_type text,
  entity_id   uuid,
  author      text,
  body        text,
  created_at  timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- Any authenticated user can read/write. App-level whitelist
-- (in index.html) controls who can sign in via magic link.
-- ============================================================
alter table "LS_factions"        enable row level security;
alter table "LS_characters"      enable row level security;
alter table "LS_character_arcs"  enable row level security;
alter table "LS_timeline_events" enable row level security;
alter table "LS_systems"         enable row level security;
alter table "LS_scenes"          enable row level security;
alter table "LS_relationships"   enable row level security;
alter table "LS_themes"          enable row level security;
alter table "LS_notes"           enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'LS_factions','LS_characters','LS_character_arcs','LS_timeline_events',
    'LS_systems','LS_scenes','LS_relationships','LS_themes','LS_notes'
  ] loop
    execute format('drop policy if exists "auth_all" on %I;', t);
    execute format(
      'create policy "auth_all" on %I for all to authenticated using (true) with check (true);', t);
  end loop;
end$$;

-- LS_notes is an APPEND-ONLY audit log: authenticated users may read and
-- insert, but never update or delete (so the trail can't be altered).
drop policy if exists "auth_all"     on "LS_notes";
drop policy if exists "notes_select" on "LS_notes";
drop policy if exists "notes_insert" on "LS_notes";
create policy "notes_select" on "LS_notes" for select to authenticated using (true);
create policy "notes_insert" on "LS_notes" for insert to authenticated with check (true);

-- ============================================================
-- SEED DATA (from LEGACY_SYSTEMS.md story bible)
-- ============================================================

-- ---------- Factions ----------
insert into "LS_factions" (name, description, color) values
  ('Legacy Team',     'Retired specialists — the last living backup of humanity''s operating manual.', '#39d353'),
  ('Young Engineers', 'Capable, modern — every system they know how to fix is also down.',            '#58a6ff'),
  ('The Sovereigns',  'Armed faction that emerged during the collapse. Organized, ideological, opportunistic. They believe the solar flare exposed the weakness of modern civilization — not a tragedy but an opening. They want the broken world to stay broken because it gives them power.', '#f85149'),
  ('The SRU',         'Systems Recovery Unit. The official current-age engineering task force. Highly credentialed, technically impressive — but after the flare, their tools are broken, their dashboards are blind, and their assumptions are failing.', '#d29922');

-- ---------- Characters ----------
-- Legacy Team
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Ruth', 'Ruth Calloway', 71, 'legacy_team',
    'Railroad dispatch / rail maps',
    'Former railroad dispatcher, Burlington Northern Santa Fe, retired 2009. Photographic memory for rail maps. Sharp, economical with words. Her whole career was making chaos legible. Moved magnetic markers on boards before she ever touched a computer. Suffers no fools.',
    'idea', id, 1 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Desmond', 'Desmond Okafor', 68, 'legacy_team',
    'Bell System telephone switching',
    'Retired Bell System switching engineer. 30 years inside telephone exchanges. Knows how to physically route a call without software. Deeply patient. Has a joke for every situation. Moral center of the group. Knows where wires go not from memory but from hands.',
    'idea', id, 2 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Patricia', 'Cmdr. Patricia Mays (Ret.)', 74, 'legacy_team',
    'Celestial / Navy navigation',
    'Former Navy navigation officer. Certified in celestial navigation, 1977. Keeps a sextant in her garage because "you never throw away a tool that works." Precise, occasionally imperious, never wrong about position. Startled when she discovers the young ensign is actually good — that''s her moment.',
    'idea', id, 3 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Harold', 'Harold Szymanski', 66, 'legacy_team',
    'Analog power plant operation',
    'Retired power plant operator, analog-era coal plant. Knows what a turbine feels like at different RPMs without instruments. Was passed over for senior roles twice for "resisting the transition." Carries bitterness about it. His arc is about letting that go. The most emotionally loaded character.',
    'idea', id, 4 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Felix', 'Felix Huang', 79, 'legacy_team',
    'HAM radio / military signals',
    'HAM radio operator and former military signals specialist. Basement full of equipment everyone teased him about for twenty years. Has been running an ad-hoc HAM network since Day 2 — already the most connected person in the country. Nobody called him. He called them. Quiet, meticulous, emotionally steady.',
    'idea', id, 5 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Ginny', 'Virginia "Ginny" Tran', 73, 'legacy_team',
    'COBOL / mainframe / batch',
    'Former mainframe programmer. COBOL. Batch processing. Punch cards at career start. Has been consulting informally since retirement because nobody replaced her knowledge — they just hoped it would never be needed. Sardonic. Has the film''s best lines. Pulls original 1971 plant documentation off microfiche.',
    'idea', id, 6 from "LS_factions" where name='Legacy Team';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Bob', 'Bob Merchant', 69, 'legacy_team',
    'Air traffic control (pre-STARS)',
    'Retired air traffic controller, pre-STARS system. Controlled aircraft with paper strips and radio. Forced out early after publicly disagreeing with FAA''s digital transition plan. Carries that grievance. Most tempted by Cole Bridger''s deal. His arc: deciding whether to let the bitterness go or use it as a weapon.',
    'idea', id, 7 from "LS_factions" where name='Legacy Team';

-- Young Engineers
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Maya', 'Maya Chen', 32, 'young_engineer',
    'Distributed systems / incident response',
    'FEMA Systems Lead. Brilliant. Knows distributed systems, redundancy architecture, incident response. Every system she knows how to fix is also down. Arc: learning that knowing how something is supposed to work and knowing how to work it manually are completely different skills. Eventually breaks from Morse to go to Sarah Park.',
    'idea', id, 8 from "LS_factions" where name='Young Engineers';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Darius', 'Lt. Col. Darius Wade', 38, 'young_engineer',
    'Army logistics / supply chain',
    'Army logistics. Harvard MBA. Has run supply chains for overseas deployments. Never moved anything without GPS routing and real-time inventory. Not arrogant — just genuinely never had to think this way before. Becomes Ruth''s most important student.',
    'idea', id, 9 from "LS_factions" where name='Young Engineers';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Sarah', 'Agent Sarah Park', 29, 'young_engineer',
    'CISA / political interface',
    'CISA. Handles the political side. Keeps trying to frame the event as a cyber incident with a recovery timeline. Has to be the one who finally tells the President: "There is no recovery timeline. There is only what we can do manually, right now." Becomes the political ally who enables the Legacy team when Morse tries to block them.',
    'idea', id, 10 from "LS_factions" where name='Young Engineers';

-- Antagonists
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Cole Bridger', 'Cole Bridger', 44, 'antagonist',
    'Logistics / militia leadership',
    'Leader of the Sovereigns. Former Army Ranger, washed out for conduct issues not competence. Understands logistics. Leads a unified network of prepper militias, accelerationist groups, and opportunistic criminals. Had been waiting for exactly this moment. Doesn''t want civilization rebooted — wants to decide what civilization becomes. His insight: the woman moving trains and the man rebuilding telephone lines are the dangerous ones.',
    'idea', id, 11 from "LS_factions" where name='The Sovereigns';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Dani Reeves', 'Dani Reeves', 26, 'antagonist',
    'Systems engineering',
    'Sovereigns member. Former systems engineer who joined not out of ideology but survival. Conscience in the enemy camp. Unresolved: whether she helps the Legacy team or not — the script needs to earn that decision.',
    'idea', id, 12 from "LS_factions" where name='The Sovereigns';
insert into "LS_characters" (name, full_name, age, role, knowledge_domain, description, status, faction_id, sort_order)
  select 'Alan Morse', 'Director Alan Morse', 51, 'antagonist',
    'SRU Director / CISA Infrastructure Recovery',
    'SRU Director. Head of CISA''s Infrastructure Recovery Division. Career bureaucrat and engineer. Genuinely brilliant, genuinely committed to public safety. Completely convinced the right answer is restoring modern systems — not working around them. Not entirely wrong: legacy solutions are temporary. The question is whether temporary-and-working beats permanent-and-not-ready-yet. Doesn''t become a villain — becomes someone who has to be right about something he was wrong about. Says: "We are not going backward." The Legacy team says: "We are keeping people alive long enough to move forward."',
    'idea', id, 13 from "LS_factions" where name='The SRU';

-- ---------- Systems (The Clock) ----------
insert into "LS_systems" (name, countdown_hours, status, description, sort_order) values
  ('Hoover Dam / Glen Canyon', 72, 'red',
   'Without power and automated controls, spillway gates default to a dangerous position. Water rising. Without manual operation within 72 hours: downstream flooding or structural failure. Manual override unused in 40 years; manuals in a dark records facility. Harold knows a man who knows a man.', 1),
  ('Nuclear Plants (cooling)', 96, 'amber',
   'Several plants in SCRAM. Most fine; three are not. Not explosion — cooling. Without power for cooling pumps, spent-fuel pools heat up. 48–96 hours to a Fukushima-level situation. Modern operators know the theory, not the manual backup cooling. Ginny pulls original 1971 documentation, half on microfiche.', 2),
  ('Mississippi Lock System', 120, 'amber',
   'Army Corps controls dozens of locks. Without them, barge traffic (60% of the nation''s grain) is impassable. Manual procedures in binders unopened since 1994; some locks have no manual override at all. Ruth''s railroad becomes the backup to the backup.', 3);

-- ---------- Relationships ----------
insert into "LS_relationships" (source_character_id, target_character_id, type, label)
  select r.id, w.id, 'mentor', 'teaches manual logistics'
  from "LS_characters" r, "LS_characters" w where r.name='Ruth' and w.name='Darius';
insert into "LS_relationships" (source_character_id, target_character_id, type, label)
  select p.id, m.id, 'ally', 'enables Legacy team politically'
  from "LS_characters" p, "LS_characters" m where p.name='Sarah' and m.name='Maya';
insert into "LS_relationships" (source_character_id, target_character_id, type, label)
  select b.id, bridger.id, 'adversary', 'tempted by the deal'
  from "LS_characters" b, "LS_characters" bridger where b.name='Bob' and bridger.name='Cole Bridger';
insert into "LS_relationships" (source_character_id, target_character_id, type, label)
  select morse.id, maya.id, 'adversary', 'Maya breaks from Morse'
  from "LS_characters" morse, "LS_characters" maya where morse.name='Alan Morse' and maya.name='Maya';

-- ---------- Themes ----------
insert into "LS_themes" (title, description, sort_order) values
  ('Knowledge vs. Information', 'Young engineers have access to all human information. Old specialists have knowledge that lives in their hands and instincts. The film argues these are not the same thing.', 1),
  ('Institutional Memory as Infrastructure', 'We treat old knowledge like outdated software. The film asks what happens when you delete your backup.', 2),
  ('The Ego of Progress', 'The real villain is the assumption that the newest system supersedes everything before it. Nobody planned for failure because failure was unthinkable.', 3),
  ('Obsolescence is Political', 'Characters were pushed out, forced to retire, passed over. Their knowledge wasn''t valued — part of why society was unprepared. The film doesn''t let this go unexamined.', 4);

-- ---------- Timeline (crisis layer) ----------
insert into "LS_timeline_events" (title, description, story_time, layer, act, type, sort_order) values
  ('The Storm', 'Carrington-class geomagnetic storm. Sept 14, 2027, 11:47 AM Eastern.', 'Hour 0', 'crisis', 'I', 'storm', 1),
  ('Satellites / GPS / cell down', 'First failures cascade.', 'Hour 0', 'crisis', 'I', 'shutdown', 2),
  ('Cloud / finance / logistics down', 'Digital infrastructure collapses.', 'Hour 2', 'crisis', 'I', 'shutdown', 3),
  ('Power grid fails', 'Grid down across large sections of North America and Europe.', 'Hour 6', 'crisis', 'I', 'shutdown', 4),
  ('AI systems fail', 'Data centers lose cooling.', 'Day 2', 'crisis', 'I', 'shutdown', 5),
  ('Society understands', 'This isn''t coming back in a week.', 'Day 4', 'crisis', 'I', 'story_beat', 6);

-- ---------- Scenes (pitch-ready, from bible) ----------
-- Scenes are stored in Fountain screenplay format (the app parses + exports them).
insert into "LS_scenes" (title, act, status, content, sort_order) values
  ('The Board (Ruth)', 'II', 'drafted',
   E'INT. RAIL DISPATCH CENTER - NIGHT\n\nAn abandoned dispatch center. The boards are still on the walls. RUTH walks in, surveys the room, picks up a magnetic marker.\n\nRUTH\nYou still have the boards?\n\nEveryone watches as she starts moving pieces. DARIUS steps closer.\n\nDARIUS\nWhat are you doing?\n\nRUTH\nI''m running trains.\n\nDARIUS\nHow?\n\nRUTH\nThe same way we did it before you were born.', 1),
  ('The Turbine (Harold)', 'II', 'drafted',
   E'INT. POWER PLANT - CONTROL ROOM - DAY\n\nYoung engineers crowd a dead control panel. HAROLD stands back. Watches. Waits.\n\nHAROLD\nYou need to stop trying to start the software.\n\nENGINEER\nSir, if we can just get the initialization sequence--\n\nHAROLD\nThere is no sequence. There''s a turbine. It needs to spin. You need to start it.\n\nENGINEER\n...How?\n\nHarold puts his hand on the casing. Closes his eyes.\n\nHAROLD\nFirst you listen.', 2),
  ('The Sextant (Patricia)', 'II', 'drafted',
   E'INT. NAVY VESSEL - PATRICIA''S QUARTERS - NIGHT\n\nA young ENSIGN finds PATRICIA at her desk, sextant out, running the math.\n\nENSIGN\nCommander... that can''t actually work, can it?\n\nPATRICIA\nIt worked for four hundred years.\n\nShe hands it to him.\n\nPATRICIA\nYour first star is Polaris. You have until dark to learn.', 3),
  ('Ginny''s Line', 'I', 'drafted',
   E'INT. EMERGENCY OPERATIONS CENTER - DAY\n\nA room full of engineers. Someone suggests calling in AI specialists.\n\nGINNY\nOur AI is down.\n\nENGINEER\nWhat about the backup?\n\nGINNY\nAlso down.\n\nENGINEER\nThe backup of the backup?\n\nGinny pulls a legal pad from her bag and sets it on the table.\n\nGINNY\nWe do it ourselves.', 4),
  ('The Final Testimony (Sarah Park)', 'III', 'drafted',
   E'INT. SENATE HEARING ROOM - DAY\n\nSARAH PARK sits at the witness table. A SENATOR leans into his microphone.\n\nSENATOR\nWhen will everything be back to normal?\n\nShe pauses.\n\nSARAH PARK\nWe''ve been building on assumptions for fifty years. We assumed every system would outlast the one before it. We assumed progress was the same as resilience. What we learned is that resilience requires memory. The people who saved us weren''t the ones who built the future. They were the ones who remembered the past.', 5);

-- done
