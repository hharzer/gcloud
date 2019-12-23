CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA util;

CREATE TABLE util.country (
    country_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    alpha2_code varchar(2) NOT NULL,
    alpha3_code varchar(3) NOT NULL,
    full_name varchar(50) NOT NULL,
    CONSTRAINT pk_country
        PRIMARY KEY (country_id),
    CONSTRAINT uq_country_alpha2_code
        UNIQUE (alpha2_code),
    CONSTRAINT uq_country_alpha3_code
        UNIQUE (alpha3_code)
);

CREATE SCHEMA customer;

CREATE TABLE customer.customer (
    customer_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Customer is uniquely identified by an email
    email varchar(50) NOT NULL,
    -- Residence country uniquely identifies the leagal entity that customer belongs to
    residence_country_id uuid NOT NULL,
    CONSTRAINT pk_customer
        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email
        UNIQUE (email),
    CONSTRAINT fk_customer_residence_country_id
        FOREIGN KEY (residence_country_id) REFERENCES util.country (country_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.beneficiary (
    beneficiary_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Beneficiary belongs only to one customer
    customer_id uuid NOT NULL,
    full_name varchar(50) NOT NULL,
    iban varchar(50) NOT NULL,
    CONSTRAINT pk_beneficiary
        PRIMARY KEY (beneficiary_id),
    CONSTRAINT fk_beneficiary_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA payment;

CREATE TABLE payment.quote (
    quote_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_quote
        PRIMARY KEY (quote_id),
    CONSTRAINT fk_beneficiary_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);
