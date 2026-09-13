# 19 — Deployment (Oracle Free Tier + Docker Compose + CI/CD)

**What to build:** One Oracle Ampere A1 instance (ARM64, up to 4 OCPU/24GB RAM), Docker Compose stack (nginx/Caddy auto-TLS reverse proxy, NestJS multi-stage Node 24 ARM image, Redis). MongoDB stays on Atlas. GitHub Actions CI/CD (backend build+test on PR; tag→build+push Docker image; build Flutter artifacts on tag).

**Blocked by:** 13, 14, 15, 16, 17, 18

**Status:** ready-for-agent

- [ ] Compose stack boots backend + redis behind TLS proxy on the Oracle instance
- [ ] Backend connects to Atlas, Redis reachable
- [ ] CI builds backend on PR and Flutter/Pod artifacts on tag
