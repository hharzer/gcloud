import got from "got";

export const getUser = async () => {
    const options: any = {};
    options.prefixUrl = `http://${process.env.API_HOST}:${process.env.API_PORT}`;
    const response: any = await got.get("users", options).json();
    const users = response.data;
    return users;
};
