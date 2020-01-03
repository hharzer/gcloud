import got from "got";

const authAdmin = (() => {
    const oauth2AdminHost = process.env.OAUTH2_ADMIN_HOST;
    const oauth2AdminPort = process.env.OAUTH2_ADMIN_PORT;
    const prefixUrl = `https://${oauth2AdminHost}:${oauth2AdminPort}`;
    const options = {prefixUrl};
    const authAdminClient = got.extend(options);
    return authAdminClient;
})();

export const getLoginRequest = async (challenge) => {
    const oauth2RequestLoginPath = `${process.env.OAUTH2_REQUEST_PATH}/login`;
    const searchParams = {login_challenge: challenge};
    const options = {searchParams};
    const response = await authAdmin.get(oauth2RequestLoginPath, options).json();
    return response;
};

export const acceptLoginRequest = async (challenge, body) => {
    const oauth2AcceptLoginPath = `${process.env.OAUTH2_REQUEST_PATH}/login/accept`;
    const searchParams = {login_challenge: challenge};
    const options = {searchParams, json: body};
    const response = await authAdmin.put(oauth2AcceptLoginPath, options).json();
    return response;
};
