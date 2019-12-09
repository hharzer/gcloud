"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const pg_1 = require("pg");
const pool = new pg_1.Pool();
exports.transaction = async (useClient) => {
    const client = await pool.connect();
    try {
        await client.query("BEGIN;");
        const result = await useClient(client);
        await client.query("COMMIT;");
        return result;
    }
    catch (error) {
        await client.query("ROLLBACK;");
        throw error;
    }
    finally {
        client.release();
    }
};
exports.buildParameters = (attributeMapping, entity) => {
    const parameters = [];
    const values = [];
    let parameterCounter = 0;
    for (const [attribute, parameter] of Object.entries(attributeMapping)) {
        if (attribute in entity) {
            parameters.push(`${parameter} := $${++parameterCounter}`);
            values.push(entity[attribute]);
        }
    }
    return [parameters, values];
};
