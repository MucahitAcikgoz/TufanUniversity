# 01 – Modül & Paket Yapısı

## Standart modül şablonu

Her modül için (ör. `identity`, `approval`) şu yapı kullanılır:

- `.../<module>/api`
  - Controller’lar (HTTP)
  - Request/Response DTO’ları
  - API-level validation
- `.../<module>/application`
  - Use-case servisleri (transaction sınırı)
  - Command/Query objeleri
  - Orchestrasyon (domain’leri çağırma)
- `.../<module>/domain`
  - Entity/Aggregate
  - Value object
  - Domain service
  - Domain event
  - Repository interface (port)
- `.../<module>/infrastructure`
  - JPA entities/repositories
  - External adapter’lar (mail, jwt, storage)
  - Spring config (SecurityConfig vs.)

## Bağımlılık yönü (en önemli kural)

`api -> application -> domain`
`infrastructure -> domain` (adapter implement eder)
`* -> shared` (shared saf olmalı)

Domain, Spring/JPA/HTTP bilmez.

## İsimlendirme önerisi

- Use-case: `...UseCase`
- Domain service: `...Policy`, `...Calculator`, `...Evaluator`
- Infrastructure adapter: `...JpaAdapter`, `...JwtAdapter`
- Controller: `...Controller`

## Paket isimleri değişirse?

Paket isimleri değişebilir.
Önemli olan: bağımlılık yönünü ve katman sınırlarını bozmamak.
