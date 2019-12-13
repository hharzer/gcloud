import {Pool} from "pg";

const pool = new Pool();

export const databasePool = () => pool;

export const transaction = async (useClient) => {
    const client = await pool.connect();
    try {
        await client.query("BEGIN;");
        const result = await useClient(client);
        await client.query("COMMIT;");
        return result;
    } catch (error) {
        await client.query("ROLLBACK;");
        throw error;
    } finally {
        client.release();
    }
};

export const buildParameters = (attributeMapping, entity) => {
    const parameters: string[] = [];
    const values: any[] = [];
    let parameterCounter = 0;
    for (const [attribute, parameter] of Object.entries(attributeMapping)) {
        if (attribute in entity) {
            parameters.push(`${parameter} := $${++parameterCounter}`);
            values.push(entity[attribute]);
        }
    }
    return [parameters, values];
};
