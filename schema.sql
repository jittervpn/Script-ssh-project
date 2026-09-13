-- ============================================================
--  Jitterx — esquema inicial (ejecutar en Supabase > SQL Editor)
-- ============================================================

create table if not exists usuarios (
  id           uuid primary key default gen_random_uuid(),
  email        text unique not null,
  password     text not null,             -- scrypt: salt:hash
  nombre       text,
  creado_en    timestamptz not null default now(),
  ultimo_login timestamptz,
  bloqueado    boolean not null default false
);

create table if not exists sesiones (
  token      text primary key,            -- hash del token, nunca el token en claro
  usuario_id uuid not null references usuarios(id) on delete cascade,
  creada_en  timestamptz not null default now(),
  expira_en  timestamptz not null,
  ip         text,
  agente     text
);
create index if not exists idx_sesiones_usuario on sesiones(usuario_id);

-- Cuentas SSH vendidas (se llenará en el paso de pagos)
create table if not exists cuentas_ssh (
  id           uuid primary key default gen_random_uuid(),
  usuario_id   uuid not null references usuarios(id) on delete cascade,
  username     text unique not null,
  password     text not null,
  servidor     text not null,
  estado       text not null default 'activa',   -- activa | vencida | suspendida
  creada_en    timestamptz not null default now(),
  expira_en    timestamptz not null
);
create index if not exists idx_cuentas_usuario on cuentas_ssh(usuario_id);

-- Registros DNS creados desde el panel (opcional, para historial)
create table if not exists registros_dns (
  id         uuid primary key default gen_random_uuid(),
  usuario_id uuid references usuarios(id) on delete set null,
  fqdn       text not null,
  ip         text not null,
  cf_id      text,
  creado_en  timestamptz not null default now(),
  expira_en  timestamptz not null
);

-- Solo el servidor accede: activamos RLS y no creamos políticas públicas.
alter table usuarios      enable row level security;
alter table sesiones      enable row level security;
alter table cuentas_ssh   enable row level security;
alter table registros_dns enable row level security;
