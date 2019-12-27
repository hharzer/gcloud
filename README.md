# Google Cloud Platform examples

## Data model and database

- Itempotent (ON CONFLICT) data model with extended data integrity (ch) and referencial
  (pk/uq, fk) constraints
- Well defined interface to data access exclusively through database functions (get,
  put, patch, delete)
- Automatic database entity auditing via database functions

## REST API

- Entity CRUD API with extensive request validation, response pagination and entity
  partial updates via PATCH
- Transactional database access
- TODO: review 12-factor app guidelines (SIGTERM: -> server.close(), pg.pool.end())
- TODO: pagination: Link: first, last, next, prev

## OAuth 2.0 and OpenId Connect identity and access management

- Hyrda /keys: JWK (key/cert pair) for TLS (HTTPS), JWT (id_token)

## Performance monitoring and alerting

- TODO

## Business metrics

- TODO

## Security scans

- TODO
