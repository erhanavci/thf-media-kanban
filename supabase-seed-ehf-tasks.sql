alter table public.tasks add column if not exists import_key text;
create unique index if not exists tasks_import_key_unique on public.tasks(import_key);

insert into public.tasks (title, description, status, task_date, import_key, created_by)
values
  ('Championship announcement post (Graphic animation) v1 + Social ads', 'Championship announcement post (Graphic animation) v1 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Mar', 'publish', '2026-03-02', '2026-03-02|Championship announcement post (Graphic animation) v1 + Social ads', null),
  ('Championship announcement post (Graphic animation) v2 + Social ads', 'Championship announcement post (Graphic animation) v2 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Mar', 'publish', '2026-03-11', '2026-03-11|Championship announcement post (Graphic animation) v2 + Social ads', null),
  ('Championship announcement post (Graphic animation) v3 + Social ads', 'Championship announcement post (Graphic animation) v3 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Mar', 'publish', '2026-03-16', '2026-03-16|Championship announcement post (Graphic animation) v3 + Social ads', null),
  ('Championship announcement post (Graphic animation) v4 + Social ads', 'Championship announcement post (Graphic animation) v4 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Mar', 'publish', '2026-03-27', '2026-03-27|Championship announcement post (Graphic animation) v4 + Social ads', null),
  ('Championship announcement post (Graphic animation) v5 + Social ads', 'Championship announcement post (Graphic animation) v5 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Apr', 'publish', '2026-04-03', '2026-04-03|Championship announcement post (Graphic animation) v5 + Social ads', null),
  ('Q&A with athletes v1', 'Q&A with athletes v1' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Apr', 'plan', '2026-04-07', '2026-04-07|Q&A with athletes v1', null),
  ('Championship announcement post (Graphic animation) v6 + Social ads', 'Championship announcement post (Graphic animation) v6 + Social ads' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Apr', 'publish', '2026-04-16', '2026-04-16|Championship announcement post (Graphic animation) v6 + Social ads', null),
  ('Q&A with athletes v2', 'Q&A with athletes v2' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Apr', 'plan', '2026-04-22', '2026-04-22|Q&A with athletes v2', null),
  ('Official promotional video', 'Official promotional video' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / May', 'production', '2026-05-04', '2026-05-04|Official promotional video', null),
  ('Official mascot', 'Official mascot' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / May', 'plan', '2026-05-11', '2026-05-11|Official mascot', null),
  ('Ticket sales announcement', 'Ticket sales announcement' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / May', 'publish', '2026-05-18', '2026-05-18|Ticket sales announcement', null),
  ('Ticket giveaway', 'Ticket giveaway' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / May', 'publish', '2026-05-29', '2026-05-29|Ticket giveaway', null),
  ('Influencer video v1', 'Influencer video v1' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jun', 'production', '2026-06-05', '2026-06-05|Influencer video v1', null),
  ('Influencer video v2', 'Influencer video v2' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jun', 'production', '2026-06-10', '2026-06-10|Influencer video v2', null),
  ('Volunteer announcement', 'Volunteer announcement' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jun', 'publish', '2026-06-19', '2026-06-19|Volunteer announcement', null),
  ('Influencer video v3', 'Influencer video v3' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jun', 'production', '2026-06-24', '2026-06-24|Influencer video v3', null),
  ('Content about handball events in Antalya', 'Content about handball events in Antalya' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jul', 'production', '2026-07-03', '2026-07-03|Content about handball events in Antalya', null),
  ('Content about handball events in Antalya', 'Content about handball events in Antalya' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jul', 'production', '2026-07-07', '2026-07-07|Content about handball events in Antalya', null),
  ('Content about handball events in Antalya', 'Content about handball events in Antalya' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jul', 'production', '2026-07-17', '2026-07-17|Content about handball events in Antalya', null),
  ('Content about handball events in Antalya', 'Content about handball events in Antalya' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Jul', 'production', '2026-07-22', '2026-07-22|Content about handball events in Antalya', null),
  ('Official song announcement', 'Official song announcement' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Sep', 'publish', '2026-09-04', '2026-09-04|Official song announcement', null),
  ('The mascot''s school visit', 'The mascot''s school visit' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Sep', 'publish', '2026-09-07', '2026-09-07|The mascot''s school visit', null),
  ('The mascot''s shopping mall visit', 'The mascot''s shopping mall visit' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Sep', 'publish', '2026-09-18', '2026-09-18|The mascot''s shopping mall visit', null),
  ('The mascot''s Antalya Sports Hall visit', 'The mascot''s Antalya Sports Hall visit' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Sep', 'live', '2026-09-23', '2026-09-23|The mascot''s Antalya Sports Hall visit', null),
  ('Turkey National Team''s player''s talks at school', 'Turkey National Team''s player''s talks at school' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Oct', 'publish', '2026-10-02', '2026-10-02|Turkey National Team''s player''s talks at school', null),
  ('Turkey National Team''s player''s talks at school', 'Turkey National Team''s player''s talks at school' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Oct', 'publish', '2026-10-16', '2026-10-16|Turkey National Team''s player''s talks at school', null),
  ('Content for visuals prepared in Antalya regarding the European Championship.', 'Content for visuals prepared in Antalya regarding the European Championship.' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Nov', 'production', '2026-11-02', '2026-11-02|Content for visuals prepared in Antalya regarding the European Championship.', null),
  ('Content for visuals prepared in Antalya regarding the European Championship.', 'Content for visuals prepared in Antalya regarding the European Championship.' || chr(10) || 'Kaynak: EHF Women''s Euro 2026.xlsx / Nov', 'production', '2026-11-20', '2026-11-20|Content for visuals prepared in Antalya regarding the European Championship.', null)
on conflict (import_key) do update set
  title = excluded.title,
  description = excluded.description,
  status = excluded.status,
  task_date = excluded.task_date;

select count(*) as imported_ehf_tasks
from public.tasks
where import_key is not null;
