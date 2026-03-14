# 04 – Güvenlik (RBAC + Scope)

## Roller
- RECTOR: global
- DEAN: kendi faculty
- HEAD: kendi department
- SECRETARY: operasyon
- TEACHER: kendi section + danışmanlık
- STUDENT: kendi verileri

## Enforce stratejisi
1) Method security: rol kontrolü
2) Service layer: scope guard (tek doğru kaynak)

## JWT
- access TTL: 30dk
- refresh DB’de hash
- logout-all: token_version++
