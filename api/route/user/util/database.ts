import {transaction, buildParameters} from "util/database";

export const putUser = async (user) => {
    const attributeMapping = {
        subject: "a_subject",
        userId: "a_user_id",
        firstName: "a_first_name",
        lastName: "a_last_name",
        birthDay: "a_birth_day",
        nationality: "a_nationality",
        email: "a_email",
    };
    const [parameters, values] = buildParameters(attributeMapping, user);
    const text = `SELECT identity.put_user(${parameters.join(", ")}) "userId";`;
    const result = await transaction(
        async (client) => await client.query({text, values})
    );
    const userId = result.rows[0].userId;
    return userId;
};

export const patchUser = async (user) => {
    const attributeMapping = {
        subject: "a_subject",
        userId: "a_user_id",
        firstName: "a_first_name",
        lastName: "a_last_name",
        birthDay: "a_birth_day",
        nationality: "a_nationality",
        email: "a_email",
    };
    const [parameters, values] = buildParameters(attributeMapping, user);
    const text = `SELECT identity.patch_user(${parameters.join(", ")}) "userId";`;
    const result = await transaction(
        async (client) => await client.query({text, values})
    );
    const userId = result.rows[0].userId;
    return userId;
};

export const getUser = async (user) => {
    const attributeMapping = {
        userId: "a_user_id",
        firstName: "a_first_name",
        lastName: "a_last_name",
        birthDay: "a_birth_day",
        nationality: "a_nationality",
        email: "a_email",
        limit: "a_limit",
        offset: "a_offset",
    };
    const [parameters, values] = buildParameters(attributeMapping, user);
    const text = `
    SELECT u.user_id "userId",
        u.first_name "firstName",
        u.last_name "lastName",
        u.birth_day::text "birthDay",
        u.nationality "nationality",
        u.email "email"
    FROM identity.get_user(${parameters.join(", ")}) u;
    `;
    const result = await transaction(
        async (client) => await client.query({text, values})
    );
    const users = result.rows;
    return users;
};

export const deleteUser = async (user) => {
    const attributeMapping = {
        userId: "a_user_id",
    };
    const [parameters, values] = buildParameters(attributeMapping, user);
    const text = `SELECT identity.delete_user(${parameters.join(", ")}) "userId";`;
    const result = await transaction(
        async (client) => await client.query({text, values})
    );
    const userId = result.rows[0].userId;
    return userId;
};
