import * as moment from "moment";
import got from "got";
import {
    BadRequestError,
    UnauthorizedError,
    ForbiddenError,
    InternalServerError,
} from "restify-errors";

const MAX_RETRY = 2;

const auth = (() => {
    const oauth2Host = process.env.OAUTH2_HOST;
    const oauth2Port = process.env.OAUTH2_PORT;
    const prefixUrl = `https://${oauth2Host}:${oauth2Port}`;
    const options = {prefixUrl};
    const authClient = got.extend(options);
    return authClient;
})();

// curl -sSLk -X POST "https://localhost:4444/oauth2/token" \
//     -u 'cc-client':'ClientCredentialsSecret' \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d 'grant_type=client_credentials&scope=custom1 custom2' \
//     | jq .

export const getOauth2ClientCredentialsToken = async (
    clientId,
    clientSecret,
    scope
) => {
    const oauth2TokenPath = process.env.OAUTH2_TOKEN_PATH ?? "UNDEFINED";
    const contentType = "application/x-www-form-urlencoded";
    const clientCredentials = Buffer.from(`${clientId}:${clientSecret}`).toString(
        "base64"
    );
    const authorization = `Basic ${clientCredentials}`;
    // prettier-ignore
    const headers = {"Content-Type": contentType, "Authorization": authorization};
    const body = `grant_type=client_credentials&scope=${scope}`;
    const options = {headers, body};
    const response = await auth.post(oauth2TokenPath, options).json();
    return response;
};

const parseHttpError = (error) => {
    const statusCode = error?.response?.statusCode ?? 500;
    const errorBody = JSON.parse(error?.response?.body ?? {message: error.message});
    const message = [
        errorBody?.error,
        errorBody?.error_description,
        errorBody?.error_hint,
        errorBody?.message,
    ]
        .filter(Boolean)
        .join(". ");
    return {statusCode, message};
};

const createRestifyError = (httpError) => {
    switch (httpError.statusCode) {
        case 400:
            return new BadRequestError(httpError.message);
        case 401:
            return new UnauthorizedError(httpError.message);
        case 403:
            return new ForbiddenError(httpError.message);
        default:
            return new InternalServerError(httpError.message);
    }
};

export const withOauth2Token = (clientId, clientSecret, scope, callApi) => {
    let token: any = null;
    return async (...args) => {
        let retryCount = 0;
        while (retryCount <= MAX_RETRY) {
            try {
                if (!token || retryCount > 0 || moment().isAfter(token.expires_at)) {
                    token = await getOauth2ClientCredentialsToken(
                        clientId,
                        clientSecret,
                        scope
                    );
                    token.expires_at = moment()
                        .add(token.expires_in, "seconds")
                        .subtract(5, "seconds");
                }
                const response = await callApi(token.access_token, ...args);
                return response;
            } catch (error) {
                const httpError = parseHttpError(error);
                if (![400, 401, 403].includes(httpError.statusCode)) {
                    throw error;
                }
                if (retryCount === MAX_RETRY) {
                    throw createRestifyError(httpError);
                }
            }
            ++retryCount;
        }
    };
};
