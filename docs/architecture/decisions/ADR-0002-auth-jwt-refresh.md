# ADR-0002: JWT (Access + Refresh) Session Yönetimi

Tarih: 2026-03-01

## Context
Oturum yönetimi: 30dk access, refresh ile yenileme; logout ve logout-all gereksinimi.

## Decision
- Access TTL: 30dk
- Refresh DB’de hash
- Logout: refresh revoke
- Logout-all: token_version++

## Consequences
+ Güvenli ve yönetilebilir
- Refresh storage mantığı ekstra iş
