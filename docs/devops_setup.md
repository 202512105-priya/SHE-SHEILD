# SHE SHIELD — DevOps & Git Workflow

## Branching Model
- `main`: Production-ready releases. Protected branch.
- `dev`: Active integration branch.
- `feature/KAN-<id>-<desc>`: Individual feature and task branches.

## CI/CD Pipeline
- Linting and unit tests run on pull requests to `main` and `dev`.
- Container images built for backend and microservices.

## Environment Architecture
- Frontend: Cross-platform Flutter client
- Backend: Python Flask microservices & API Gateway
- Database: PostgreSQL & Redis
- Cloud Services: Emergency SMS & Push Notification dispatchers
