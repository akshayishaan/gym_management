# Gym Management

Mobile-first, multi-tenant gym management SaaS built with Next.js 15, React 19, MongoDB/Mongoose, and NextAuth v4.

## Local development

Requires Node.js 24.x.

```bash
cp .env.example .env
npm ci
npm run dev
```

The application always connects to an external, transaction-capable MongoDB deployment. It does not provision a local database.

## Deploy to Vercel

1. Import this repository into Vercel and keep the detected Next.js defaults.
2. Configure these Production environment variables:
   - `MONGODB_URI`
   - `MONGODB_USERNAME` and `MONGODB_PASSWORD` when credentials are not embedded in the URI
   - `NEXTAUTH_SECRET`
   - `NEXTAUTH_URL`, set to the final `https://` deployment domain
3. Deploy, then create the initial administrator through `/login` → **Sign Up**.

MongoDB must support transactions; MongoDB Atlas is suitable. Vercel Hobby deployments do not have fixed outbound IP addresses, so configure Atlas network access accordingly and use strong database credentials. Do not commit `.env` or Vercel's local `.vercel` directory.

Vercel's Hobby plan is generally intended for personal, non-commercial use. Check the current Vercel terms before using it for a commercial gym operation; a paid plan may be required even though the application is technically compatible with Hobby limits.

## Verification

```bash
npm run build
```
