import got from "got";

const authAdmin = (() => {
    const oauth2AdminHost = process.env.OAUTH2_ADMIN_HOST;
    const oauth2AdminPort = process.env.OAUTH2_ADMIN_PORT;
    const prefixUrl = `https://${oauth2AdminHost}:${oauth2AdminPort}`;
    const options = {prefixUrl};
    const authAdminClient = got.extend(options);
    return authAdminClient;
})();

// TOKEN=$(curl -sSLk -X POST "https://localhost:4444/oauth2/token" \
//     -u 'cc-client':'ClientCredentialsSecret' \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d 'grant_type=client_credentials&scope=custom1 custom2' \
//     | jq -r '.access_token' \
// )
// curl -sSLk -X POST "https://localhost:4445/oauth2/introspect" \
//     -H 'Content-Type: application/x-www-form-urlencoded' \
//     -d "token=$TOKEN&scope=custom1 custom2" \
//     | jq .

export const introspectOAuth2Token = async (oauth2Token, scope) => {
    const oauth2IntrospectPath = process.env.OAUTH2_INTROSPECT_PATH ?? "UNDEFINED";
    const contentType = "application/x-www-form-urlencoded";
    const headers = {"Content-Type": contentType};
    const body = `token=${oauth2Token}&scope=${scope}`;
    const options = {headers, body};
    const response = await authAdmin.post(oauth2IntrospectPath, options).json();
    return response;
};
