-- identity_api_role
CREATE ROLE identity_api_role;
GRANT USAGE ON SCHEMA identity TO identity_api_role;
GRANT SELECT, INSERT, UPDATE, DELETE
   ON TABLE identity.user, identity.user_audit TO identity_api_role;
CREATE ROLE identity_api WITH PASSWORD 'Password1!' LOGIN;
GRANT identity_api_role TO identity_api;
