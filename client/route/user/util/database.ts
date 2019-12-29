import got from "got";

export const getUser = async () => {
    const apiHost = process.env.API_HOST;
    const apiPort = process.env.API_PORT;
    const userPath = "users";
    const options: any = {};
    options.prefixUrl = `http://${apiHost}:${apiPort}`;
    const response: any = await got.get(userPath, options).json();
    const users = response.data;
    return users;
};
