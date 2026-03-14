# 02 – Katman Kuralları (API / Application / Domain / Infrastructure)

## API (`api`)
HTTP ile ilgili her şey:
- Controller
- Request/Response DTO
- Validation

## Application (`application`)
Use-case yürütür:
- Transaction sınırı
- Domain’i çağırır, akışı yönetir
- Port interface’leri kullanır

## Domain (`domain`)
İş modeli:
- Entity/Aggregate, Value Object
- Domain Service/Policy
- Domain Events
- Repository interface (port)

## Infrastructure (`infrastructure`)
Dış dünya:
- JPA entities/repositories
- JWT, mail, storage
- Spring config

## DTO / Command / Query
- API DTO: HTTP formatı
- Command/Query: use-case giriş/çıkış
- Domain: iş modeli (DTO değil)

## Transaction
Use-case seviyesinde olmalı (`@Transactional`).
