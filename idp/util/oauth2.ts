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

export const rejectLoginRequest = async (challenge, body) => {
    const oauth2RejectLoginPath = `${process.env.OAUTH2_REQUEST_PATH}/login/reject`;
    const searchParams = {login_challenge: challenge};
    const options = {searchParams, json: body};
    const response = await authAdmin.put(oauth2RejectLoginPath, options).json();
    return response;
};

export const getConsentRequest = async (challenge) => {
    const oauth2RequestConsentPath = `${process.env.OAUTH2_REQUEST_PATH}/consent`;
    const searchParams = {consent_challenge: challenge};
    const options = {searchParams};
    const response = await authAdmin.get(oauth2RequestConsentPath, options).json();
    return response;
};

export const acceptConsentRequest = async (challenge, body) => {
    const oauth2AcceptConsentPath = `${process.env.OAUTH2_REQUEST_PATH}/consent/accept`;
    const searchParams = {consent_challenge: challenge};
    const options = {searchParams, json: body};
    const response = await authAdmin.put(oauth2AcceptConsentPath, options).json();
    return response;
};

export const rejectConsentRequest = async (challenge, body) => {
    const oauth2RejectConsentPath = `${process.env.OAUTH2_REQUEST_PATH}/consent/reject`;
    const searchParams = {consent_challenge: challenge};
    const options = {searchParams, json: body};
    const response = await authAdmin.put(oauth2RejectConsentPath, options).json();
    return response;
};
