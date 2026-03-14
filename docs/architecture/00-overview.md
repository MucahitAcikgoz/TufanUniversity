# 00 – Overview

## Projenin amacı

TufanUniversity, bir üniversite otomasyon sistemidir.
MVP odakları:
- Kimlik doğrulama (JWT access + refresh)
- RBAC + scope (rektör/dekan/bölüm başkanı sınırları)
- Approval engine (policy + delegation)
- Term & enrollment windows (öğrenci/danışman/bölüm başkanı)
- Course/Section/Meeting
- Enrollment state machine + waitlist
- Grades (0–100 + harf + curve) + review workflow
- Documents (PDF) + audit log + notifications

## Bounded Context / Modül Haritası

Aşağıdaki modüller bounded context gibi düşünülür; birbirinin iç modeline doğrudan erişmez.

- `identity`: auth, kullanıcı, rol, token
- `organization`: university/campus/faculty/department
- `approval`: request, policy, delegation, karar kayıtları
- `term`: term, windows, danışman atama
- `academic`: course, section, meeting, prerequisite
- `enrollment`: enrollment, waitlist, kapasite rezervasyonu
- `grades`: numeric/letter, thresholds, curve, review
- `documents`: student certificate, transcript, verification
- `notifications`: email/inbox bildirimleri
- `shared`: error format, clock, audit, common utilities

## “Data Ownership” (kimin verisi kime ait?)

- `identity` kullanıcı/rol/token verisinin sahibidir.
- `organization` kampüs/fakülte/bölümün sahibidir.
- `term` term ve windows’un sahibidir.
- `academic` course/section/meeting’in sahibidir.
- `enrollment` enrollment + waitlist’in sahibidir.
- `grades` grade/curve/review’un sahibidir.
- `approval` approval request/policy’nin sahibidir.

Bir modül başka bir modülün tablosuna “iş kuralı” yazmaz.
En fazla read-only erişim (projection/query) yapılır.

## Teknik yaklaşım

- Spring Boot
- Flyway (V1 schema, V2 seed)
- PostgreSQL
- Testcontainers (integration tests)
- Modüler/DDD katmanlama
- (İleride) Event-driven entegrasyon (domain events + outbox)

## Hedef kalite kriterleri

- İş kuralları domain/application’da, framework bağımlılığı infrastructure’da olsun
- Transaction sınırları application use-case seviyesinde olsun
- En az 1-2 kritik akış için state machine net tanımlansın (enrollment, approval)
- Audit log: kritik değişiklikler izlenebilir olsun
