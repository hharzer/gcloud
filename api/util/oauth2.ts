import got from "got";

// TOKEN=$(curl -s -k -X POST "https://localhost:4444/oauth2/token" \
//     -u 'cc-client':'ClientCredentialsSecret' \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d 'grant_type=client_credentials&scope=custom1 custom2' \
//     | jq -r '.access_token' \
// )
// curl -s -k -X POST "https://localhost:4445/oauth2/introspect" \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d "token=$TOKEN&scope=custom1 custom2" \
//     | jq .

export const introspectOAuth2Token = async (oauth2Token, scope) => {
    const oauth2Host = process.env.OAUTH2_ADMIN_HOST;
    const oauth2Port = process.env.OAUTH2_ADMIN_PORT;
    const oauth2IntrospectPath = process.env.OAUTH2_INTROSPECT_PATH ?? "UNDEFINED";
    const options: any = {};
    options.prefixUrl = `https://${oauth2Host}:${oauth2Port}`;
    const headers: any = {};
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    options.headers = headers;
    options.body = `token=${oauth2Token}&scope=${scope}`;
    const response = await got.post(oauth2IntrospectPath, options).json();
    return response;
};
