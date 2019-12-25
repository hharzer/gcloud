import {getOauth2ClientCredentialsToken} from "util/oauth2";

const main = async () => {
    try {
        const response = await getOauth2ClientCredentialsToken(
            process.env.OAUTH2_HOST,
            process.env.OAUTH2_PORT,
            process.env.OAUTH2_TOKEN_PATH,
            process.env.OAUTH2_CC_CLIENT_ID,
            process.env.OAUTH2_CC_CLIENT_SECRET,
            "custom1 custom2"
        );
        console.log(response);
    } catch (error) {
        const errorReponse = {
            code: error.name,
            message: error.message,
            detail: JSON.parse(error?.response?.body ?? null),
        };
        console.error(errorReponse);
        process.exit(1);
    }
};

main();
