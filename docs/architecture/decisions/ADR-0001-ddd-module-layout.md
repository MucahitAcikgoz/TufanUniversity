# ADR-0001: DDD Modüler Paket Yapısı

Tarih: 2026-03-01

## Context
Proje büyüyecek. Modülerlik ve test edilebilirlik hedefleniyor.

## Decision
Her bounded context için: api/application/domain/infrastructure yapısı kullanılacak.

## Alternatives
- Global layer bazlı paket (controller/service/repository)
- Hexagonal tek klasör (ports/adapters)

## Consequences
+ Sınırlar netleşir
+ Domain saf kalır
- Başta daha fazla dosya oluşur
