-- Persistent, privacy-minimized results for the student-guidance quiz.
-- Public readers can see masked display names and scores; no full student name is stored.
create table if not exists public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  display_name text not null check (char_length(display_name) between 1 and 40),
  score numeric(3,1) not null check (score between 0 and 10),
  correct_count smallint not null check (correct_count between 0 and 20),
  total_questions smallint not null default 20 check (total_questions = 20),
  created_at timestamptz not null default now(),
  constraint quiz_results_score_matches_answers
    check (score = round(correct_count::numeric / 2, 1))
);

create index if not exists quiz_results_created_at_idx
  on public.quiz_results (created_at desc);

alter table public.quiz_results enable row level security;

revoke all on public.quiz_results from public, anon, authenticated;
grant select, insert on public.quiz_results to anon, authenticated;

drop policy if exists "Quiz results are publicly readable" on public.quiz_results;
create policy "Quiz results are publicly readable"
  on public.quiz_results
  for select
  to anon, authenticated
  using (true);

drop policy if exists "Visitors can add valid quiz results" on public.quiz_results;
create policy "Visitors can add valid quiz results"
  on public.quiz_results
  for insert
  to anon, authenticated
  with check (
    char_length(trim(display_name)) between 1 and 40
    and correct_count between 0 and 20
    and total_questions = 20
    and score = round(correct_count::numeric / 2, 1)
  );
