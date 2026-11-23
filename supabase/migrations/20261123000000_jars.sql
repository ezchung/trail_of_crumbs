-- Jars and their event history. Paste into Supabase → SQL Editor → Run
-- (or `supabase db push` if you use the Supabase CLI).
--
-- Mirrors SourdoughCore: a jar stores only its history (jar_events).
-- Grams and the face are worked out in Swift, never stored here.

create table public.jars (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
    name        text not null check (char_length(name) between 1 and 60),
    type        text not null check (type in ('starter', 'bread', 'pizza')),
    schedule_hours int not null default 12 check (schedule_hours in (12, 24)),
    created_at  timestamptz not null default now()
);

create table public.jar_events (
    id       uuid primary key default gen_random_uuid(),
    jar_id   uuid not null references public.jars (id) on delete cascade,
    user_id  uuid not null default auth.uid() references auth.users (id) on delete cascade,
    at       timestamptz not null,
    kind     text not null check (kind in (
                 'started', 'fed', 'took_out', 'added_water',
                 'moved_to_fridge', 'moved_to_counter', 'reported')),

    -- Only the columns a kind needs are filled; the rest stay null.
    grams          double precision check (grams >= 0),      -- started, took_out, added_water
    is_new_starter boolean,                                  -- started
    kept           double precision check (kept >= 0),       -- fed
    flour          double precision check (flour >= 0),      -- fed
    water          double precision check (water >= 0),      -- fed
    reason         text check (reason in ('bake', 'discard', 'gaveAway')),  -- took_out
    report         text check (report in (
                       'liquid_on_top', 'dry_or_thick', 'pink_streaks', 'peaked', 'doubled')),
    heavy          boolean                                   -- report = liquid_on_top
);

create index jar_events_jar_at on public.jar_events (jar_id, at);
create index jars_user on public.jars (user_id);

-- Row-level security: every user sees and changes only their own rows.
alter table public.jars enable row level security;
alter table public.jar_events enable row level security;

create policy "own jars" on public.jars
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- An event must belong to you AND point at one of your jars.
create policy "own events" on public.jar_events
    for all using (user_id = auth.uid())
    with check (
        user_id = auth.uid()
        and exists (select 1 from public.jars j where j.id = jar_id and j.user_id = auth.uid())
    );
