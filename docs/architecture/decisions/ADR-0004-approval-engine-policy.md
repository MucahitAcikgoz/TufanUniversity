# ADR-0004: Approval Engine (Policy + Delegation)

Tarih: 2026-03-01

## Context
Birçok işlem onaya tabi; onay mercii policy ile değişebilmeli; delegation olmalı.

## Decision
- approval_requests + approval_policies + approval_delegations
- request_type -> handler (Command pattern)

## Consequences
+ Tek mekanizma
- payload_json standardı disiplin ister
