# 03 – Domain Modelleme (DDD)

## Aggregate
Tutarlılık sınırı. Invariant’ları korur.

Örnek aggregate adayları:
- User
- ApprovalRequest
- Enrollment
- GradeReviewRequest

## Entity vs Value Object
- Entity: kimlik (id) var
- Value object: değere göre eşitlik (Email, TermWindow)

## Domain Service/Policy
- EnrollmentPolicy
- ScopePolicy
- ApprovalPolicyEvaluator

## Domain Events
- EnrollmentApproved
- ApprovalRequestApproved
- GradeFinalized
