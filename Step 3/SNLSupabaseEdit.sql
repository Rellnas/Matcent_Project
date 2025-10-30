create or replace function execute_query(query text)
returns setof record
language plpgsql
as
$$
begin
    return query execute query;
end;
$$;

-- Grant permission untuk anon users (jika diperlukan)
grant execute on function execute_query(text) to anon;
grant execute on function execute_query(text) to authenticated;

-- Enable RLS pada semua tables
alter table employees enable row level security;
alter table competencies_yearly enable row level security;
alter table profiles_psych enable row level security;
alter table papi_scores enable row level security;
alter table strengths enable row level security;
alter table performance_yearly enable row level security;
alter table dim_competency_pillars enable row level security;

-- Create SELECT policies untuk public access
create policy "allow_select" on employees for select using (true);
create policy "allow_select" on competencies_yearly for select using (true);
create policy "allow_select" on profiles_psych for select using (true);
create policy "allow_select" on papi_scores for select using (true);
create policy "allow_select" on strengths for select using (true);
create policy "allow_select" on performance_yearly for select using (true);
create policy "allow_select" on dim_competency_pillars for select using (true);

-- Grant execute permission
grant execute on function execute_query(text) to anon, authenticated, service_role;
