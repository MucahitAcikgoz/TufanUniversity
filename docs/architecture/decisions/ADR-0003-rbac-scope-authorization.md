# ADR-0003: RBAC + Scope Enforcement

Tarih: 2026-03-01

## Context
Dekan ve bölüm başkanı sadece kendi scope’larında işlem yapmalı.

## Decision
- Rol kontrolü: method security
- Scope kontrolü: service-layer guard

## Consequences
+ Güvenli ve merkezi kontrol
- Bazı kontroller tekrar edebilir (helper ile azaltılır)
