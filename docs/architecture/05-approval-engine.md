# 05 – Approval Engine

## Amaç
Onaya tabi işlemleri tek mekanizma ile yönetmek.

## Tablolar
- approval_requests
- approval_policies
- approval_delegations

## Policy evaluation zinciri
1) Delegation var mı?
2) Policy var mı?
3) Approver role + scope
4) Fallback: Rector

## Execute yaklaşımı
request_type -> handler (Command pattern)
