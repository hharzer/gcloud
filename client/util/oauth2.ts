import got from "got";

// curl -s -k -X POST "https://localhost:4444/oauth2/token" \
//     -u 'cc-client':'ClientCredentialsSecret' \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d 'grant_type=client_credentials&scope=custom1 custom2' \
//     | jq .

export const getOauth2ClientCredentialsToken = async (
    clientId,
    clientSecret,
    scope
) => {
    const oauth2Host = process.env.OAUTH2_HOST;
    const oauth2Port = process.env.OAUTH2_PORT;
    const oauth2TokenPath = process.env.OAUTH2_TOKEN_PATH ?? "UNDEFINED";
    const options: any = {};
    options.prefixUrl = `https://${oauth2Host}:${oauth2Port}`;
    const headers: any = {};
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    const clientCredentials = Buffer.from(`${clientId}:${clientSecret}`).toString(
        "base64"
    );
    headers["Authorization"] = `Basic ${clientCredentials}`;
    options.headers = headers;
    options.body = `grant_type=client_credentials&scope=${scope}`;
    const response = await got.post(oauth2TokenPath, options).json();
    return response;
};

// curl -s -k -X GET "https://localhost:4444/oauth2/auth"\
// "?response_type=code&client_id=ac-client"\
// "&scope=offline_access openid custom1 custom2"\
// "&redirect_uri=http://localhost:7070/callback&state=randomstate"

export const getOauth2AuthorizationCodeToken = async (clientId, redirectUri, scope) => {
    const oauth2Host = process.env.OAUTH2_HOST;
    const oauth2Port = process.env.OAUTH2_PORT;
    const oauth2AuthPath = process.env.OAUTH2_AUTH_PATH ?? "UNDEFINED";
    const options: any = {};
    options.prefixUrl = `https://${oauth2Host}:${oauth2Port}`;
    const searchParams: any = {};
    searchParams["response_type"] = "code";
    searchParams["client_id"] = clientId;
    searchParams["scope"] = scope;
    searchParams["redirect_uri"] = redirectUri;
    searchParams["state"] = "randomstate";
    options.searchParams = searchParams;
    const response = got.get(oauth2AuthPath, options);
    return response;
};
