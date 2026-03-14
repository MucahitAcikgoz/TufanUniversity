# Architecture Docs (TufanUniversity)

Bu klasör, projenin **mimari kararlarını**, **modül sınırlarını**, **katman kurallarını** ve feature bazlı akışları dokümante eder.
Amaç: 6 ay sonra bile projeye döndüğünde “neden böyle yaptık?” sorusunun cevabı burada olsun.

## Nasıl kullanılır?

- Yeni bir karar aldığında (paket yapısı, auth, policy motoru, event yaklaşımı gibi) mutlaka bir **ADR** ekle:
  - `docs/architecture/decisions/ADR-XXXX-....md`
- Feature geliştirirken önce ilgili dokümana bak:
  - Örn: JWT → `04-security-rbac-scope.md` + `ADR-0002-auth-jwt-refresh.md`
  - Approval → `05-approval-engine.md` + `ADR-0004-approval-engine-policy.md`
- Diagram çiziyorsan:
  - Kaynağını `docs/diagrams/` içine koy (draw.io / plantuml / mermaid kaynakları)
  - Export PNG/PDF’yi de yanına koy (PR review’da hızlı görülür)

## Dokümantasyon Prensipleri

- **Kısa ama net:** Gereksiz uzun roman değil, kararların nedeni ve sonucu.
- **Tek kaynak:** Kurallar bir yerde yazsın, “iki farklı dosyada çelişen” bilgi olmasın.
- **Version kontrol dostu:** Mermaid/PlantUML gibi text tabanlı diyagramları tercih et.
- **Güncellik:** Kod değiştiğinde ilgili dokümanı da güncelle (özellikle ADR’leri).

## İçerik Haritası

- Genel: `00-overview.md`
- Modüller ve paket yapısı: `01-module-layout.md`
- Katman kuralları ve bağımlılıklar: `02-layering-rules.md`
- DDD/domain modelleme: `03-domain-modeling.md`
- Güvenlik (RBAC + Scope): `04-security-rbac-scope.md`
- Approval Engine: `05-approval-engine.md`
- Enrollment akışı: `06-enrollment-state-machine.md`
- Grades/Curve: `07-grading-curve.md`
- Audit/Notifications: `08-notifications-audit.md`
- Kararlar (ADR): `decisions/`

Tarih: 2026-03-01
