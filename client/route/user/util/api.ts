import got from "got";

const api = (() => {
    const apiHost = process.env.API_HOST;
    const apiPort = process.env.API_PORT;
    const prefixUrl = `http://${apiHost}:${apiPort}`;
    const options = {prefixUrl};
    const apiClient = got.extend(options);
    return apiClient;
})();

export const getUser = async (accessToken) => {
    const userPath = "users";
    const authorization = `Bearer ${accessToken}`;
    const headers = {Authorization: authorization};
    const options = {headers};
    const response: any = await api.get(userPath, options).json();
    const users = response.data;
    return users;
};
