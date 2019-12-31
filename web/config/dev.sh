export WEB_PORT=4002

export API_HOST=localhost
export API_PORT=4001

export OAUTH2_HOST=localhost
export OAUTH2_PORT=4444
export OAUTH2_AUTH_PATH=/oauth2/auth
export OAUTH2_TOKEN_PATH=/oauth2/token

export OAUTH2_CC_CLIENT_ID=cc-client
export OAUTH2_CC_CLIENT_SECRET=ClientCredentialsSecret
export OAUTH2_AC_CLIENT_ID=ac-client
export OAUTH2_AC_CLIENT_SECRET=AuthorizationCodeSecret
export OAUTH2_AC_CLIENT_REDIRECT_URI=http://localhost:$WEB_PORT/callback
