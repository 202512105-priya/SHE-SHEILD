# Database Architecture Specifications

Database table relationships and indexing:
- Users Table -> PK (id)
- Roles Table -> PK (id), User references Role FK (role_id)
- Complaints Table -> PK (id), User references User FK (user_id)
- Indexes needed: User username lookup index, Location indexes.