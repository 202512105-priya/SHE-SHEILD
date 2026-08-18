# SHE SHIELD — Platform Integration & Cloud Architecture

## Service Topology
1. **API Gateway / Proxy**: Handles CORS, JWT token verification, and routes incoming mobile client traffic.
2. **Backend API Service**: Python Flask service managing core application business logic, users, and cases.
3. **AI Threat Detection Service**: Isolated microservice for text/image harassment inference.
4. **Cloud Notification Dispatcher**: Webhook connectors for emergency SMS (Twilio/AWS SNS) and Push Notifications (FCM).
5. **Data Layer**: PostgreSQL for structured entities; Redis for telemetry caching and session buffering.

## Network Orchestration
Internal communication between microservices uses Docker bridge network `sheshield-net` with private DNS resolution.
