---
status: accepted
---

# Represent Membership periods as Gym-local dates

A Membership period is an inclusive sequence of calendar days interpreted in the Gym's authoritative IANA timezone. Membership start and expiry values will be stored as validated `YYYY-MM-DD` dates, while Payment and Refund times remain timestamps; existing Membership and Member date values must be migrated using their Gym's timezone. Date-only persistence is preferred over BSON timestamp instants because browser and server timezone conversions must not change a Member's final day of access.
