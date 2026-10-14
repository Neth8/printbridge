-- PRINTBRIDGE SCHEMA — Run once in Supabase SQL Editor.
-- Auth users are created in Supabase Authentication → Users (never store passwords in these tables).
create extension if not exists pgcrypto;
create table if not exists public.printbridge_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.printbridge_brands (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (length(trim(name)) between 1 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.printbridge_dealers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (length(trim(name)) between 1 and 150),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.printbridge_devices (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid not null references public.printbridge_brands(id) on delete restrict,
  model text not null check (length(trim(model)) between 1 and 160),
  description text not null default '',
  device_type text not null default 'label' check (device_type in ('label','receipt','scanner','other')),
  image_url text not null default '',
  active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique(brand_id, model)
);
create table if not exists public.printbridge_resources (
  id uuid primary key default gen_random_uuid(),
  device_id uuid references public.printbridge_devices(id) on delete set null,
  title text not null check (length(trim(title)) between 1 and 200),
  kind text not null check (kind in ('driver','bartender','utility','manual')),
  os text not null default 'All',
  version text not null default '',
  notes text not null default '',
  download_url text not null check (download_url ~* '^https://[^[:space:]]+$'),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.printbridge_support_requests (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (length(trim(customer_name)) between 1 and 120),
  mobile text not null check (length(trim(mobile)) between 5 and 30),
  dealer_id uuid references public.printbridge_dealers(id) on delete set null,
  invoice_reference text not null default '',
  device_model text not null check (length(trim(device_model)) between 1 and 160),
  issue_type text not null check (length(trim(issue_type)) between 1 and 100),
  description text not null default '',
  consent boolean not null default false check (consent = true),
  status text not null default 'new' check (status in ('new','in_progress','resolved','closed')),
  created_at timestamptz not null default now()
);
create index if not exists printbridge_devices_brand_idx on public.printbridge_devices(brand_id);
create index if not exists printbridge_resources_device_idx on public.printbridge_resources(device_id);
create index if not exists printbridge_support_created_idx on public.printbridge_support_requests(created_at desc);

-- Locked-down admin membership lookup: no public read of the admin list.
create or replace function public.printbridge_is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.printbridge_admins where user_id = (select auth.uid()));
$$;
revoke all on function public.printbridge_is_admin() from public;
-- Anonymous visitors can call the boolean check; it returns false without a session.
grant execute on function public.printbridge_is_admin() to anon, authenticated;

alter table public.printbridge_admins enable row level security;
alter table public.printbridge_brands enable row level security;
alter table public.printbridge_dealers enable row level security;
alter table public.printbridge_devices enable row level security;
alter table public.printbridge_resources enable row level security;
alter table public.printbridge_support_requests enable row level security;

-- Public may READ active catalogue only; admins can manage full records.
create policy "pb brands public read" on public.printbridge_brands for select to anon, authenticated using (active or public.printbridge_is_admin());
create policy "pb brands admin insert" on public.printbridge_brands for insert to authenticated with check (public.printbridge_is_admin());
create policy "pb brands admin update" on public.printbridge_brands for update to authenticated using (public.printbridge_is_admin()) with check (public.printbridge_is_admin());
create policy "pb brands admin delete" on public.printbridge_brands for delete to authenticated using (public.printbridge_is_admin());
create policy "pb dealers public read" on public.printbridge_dealers for select to anon, authenticated using (active or public.printbridge_is_admin());
create policy "pb dealers admin insert" on public.printbridge_dealers for insert to authenticated with check (public.printbridge_is_admin());
create policy "pb dealers admin update" on public.printbridge_dealers for update to authenticated using (public.printbridge_is_admin()) with check (public.printbridge_is_admin());
create policy "pb dealers admin delete" on public.printbridge_dealers for delete to authenticated using (public.printbridge_is_admin());
create policy "pb devices public read" on public.printbridge_devices for select to anon, authenticated using (active or public.printbridge_is_admin());
create policy "pb devices admin insert" on public.printbridge_devices for insert to authenticated with check (public.printbridge_is_admin());
create policy "pb devices admin update" on public.printbridge_devices for update to authenticated using (public.printbridge_is_admin()) with check (public.printbridge_is_admin());
create policy "pb devices admin delete" on public.printbridge_devices for delete to authenticated using (public.printbridge_is_admin());
create policy "pb resources public read" on public.printbridge_resources for select to anon, authenticated using (active or public.printbridge_is_admin());
create policy "pb resources admin insert" on public.printbridge_resources for insert to authenticated with check (public.printbridge_is_admin());
create policy "pb resources admin update" on public.printbridge_resources for update to authenticated using (public.printbridge_is_admin()) with check (public.printbridge_is_admin());
create policy "pb resources admin delete" on public.printbridge_resources for delete to authenticated using (public.printbridge_is_admin());
-- No public SELECT on private customer information. Only allow initial creation with safe status.
create policy "pb requests public submit" on public.printbridge_support_requests for insert to anon, authenticated with check (status = 'new' and consent = true);
create policy "pb requests admin read" on public.printbridge_support_requests for select to authenticated using (public.printbridge_is_admin());
create policy "pb requests admin update" on public.printbridge_support_requests for update to authenticated using (public.printbridge_is_admin()) with check (public.printbridge_is_admin());
create policy "pb requests admin delete" on public.printbridge_support_requests for delete to authenticated using (public.printbridge_is_admin());

-- Seed models only. Add real verified MEGA URLs through the Admin UI.
insert into public.printbridge_brands(name) values ('BARZEN'),('SlipX') on conflict(name) do nothing;
insert into public.printbridge_devices(brand_id,model,description,device_type,image_url,sort_order)
select b.id,v.model,v.description,v.device_type,v.image_url,v.sort_order
from (values
  ('BARZEN','D424','4-inch barcode label printer','label','assets/barzen-d424.webp',1),
  ('BARZEN','2120TFN','2-inch barcode label printer','label','assets/barzen-2120tfn.webp',2),
  ('SlipX','C250I','Thermal receipt printer','receipt','assets/slipx-c250i.webp',3)
) as v(brand,model,description,device_type,image_url,sort_order)
join public.printbridge_brands b on b.name = v.brand
on conflict(brand_id,model) do nothing;

-- AFTER creating an auth user, authorize that user's UUID (replace placeholder):
-- insert into public.printbridge_admins(user_id) values ('PUT-AUTH-USER-UUID-HERE');
-- Never expose the service_role key in GitHub or browser JavaScript.
