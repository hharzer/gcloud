import got from "got";

// curl -s -k -X POST "https://localhost:4444/oauth2/token" \
//     -u 'cc-client':'ClientCredentialsSecret' \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d 'grant_type=client_credentials&scope=custom' \
//     | jq .

export const getOauth2ClientCredentialsToken = async (
    oauth2Host,
    oauth2Port,
    oauth2TokenPath,
    clientId,
    clientSecret,
    scope
) => {
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
