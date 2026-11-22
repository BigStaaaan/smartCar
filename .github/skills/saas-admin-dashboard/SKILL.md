---
name: saas-admin-dashboard
description: "Build and review SmartCar SaaS admin dashboard features. Use for: React TypeScript dashboards, verification queues, tables, admin authentication, API integration, accessibility, loading and error states."
---

# SaaS Admin Dashboard

Use the existing `admin-dashboard/` React TypeScript application.

## Workflow

1. Reuse existing App, Router, layout, API and Firebase auth patterns.
2. Build one complete admin workflow at a time.
3. Keep verification work inside `src/features/university-verification/`.
4. Use the shared API client for authenticated backend requests.
5. Add loading, empty, success and error states.
6. Keep admin-only actions protected by backend authorization.
7. Build and type-check the dashboard before reporting success.
