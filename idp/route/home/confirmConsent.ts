import {
    getConsentRequest,
    acceptConsentRequest,
    rejectConsentRequest,
} from "util/oauth2";

const parseRequest = (req, res, next) => {
    const challenge = req.body.challenge;
    const grant = req.body.grant;
    const grantedScope = req.body.grantedScope;
    const remember = Boolean(req.body.remember);
    const request = {challenge, grant, grantedScope, remember};
    req.request = request;
    next();
};

const executeRequest = async (req, res, next) => {
    const {challenge, grant, grantedScope, remember} = req.request;
    try {
        const consentRequest: any = await getConsentRequest(challenge);
        const {
            requested_access_token_audience: requestedAudience,
            requested_scope: requestedScope,
        } = consentRequest;
        if (grant === "Allow") {
            const consent = {
                grant_access_token_audience: requestedAudience,
                grant_scope: grantedScope,
                remember,
                remember_for: 60,
            };
            const {redirect_to: redirectTo}: any = await acceptConsentRequest(
                challenge,
                consent
            );
            const response = {redirectTo};
            res.response = response;
        } else {
            const error = "access_denied";
            const errorDescription = "Resource owner denied access";
            const consentError = {error, error_description: errorDescription};
            const {redirect_to: redirectTo}: any = await rejectConsentRequest(
                challenge,
                consentError
            );
            const response = {redirectTo};
            res.response = response;
        }
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const {redirectTo} = res.response;
    res.redirect(302, redirectTo, next);
};

export const addRoute = (server, route) => {
    server.post(`${route}/consent`, parseRequest, executeRequest, formatResponse);
};
