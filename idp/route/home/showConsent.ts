import {BadRequestError} from "restify-errors";
import {getConsentRequest, acceptConsentRequest} from "util/oauth2";

const parseRequest = (req, res, next) => {
    const consentChallenge = req.query.consent_challenge;
    const request = {consentChallenge};
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const {consentChallenge} = req.request;
    try {
        if (!consentChallenge) {
            throw new BadRequestError("Missing or empty consent_challenge");
        }
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    const {consentChallenge} = req.request;
    try {
        const consentRequest: any = await getConsentRequest(consentChallenge);
        const {
            challenge,
            skip,
            subject,
            requested_access_token_audience: requestedAudience,
            requested_scope: requestedScope,
        } = consentRequest;
        const {client_name: clientName, client_id: clientId} = consentRequest.client;
        if (skip) {
            const consent = {
                challenge,
                grant_access_token_audience: requestedAudience,
                grant_scope: requestedScope,
            };
            const {redirect_to: redirectTo}: any = await acceptConsentRequest(
                challenge,
                consent
            );
            const response = {redirectTo};
            res.response = response;
        } else {
            const showConsent = true;
            const consent = {
                title: "IdP - Consent",
                challenge,
                subject,
                clientName,
                clientId,
                requestedAudience,
                requestedScope,
            };
            const response = {showConsent, ...consent};
            res.response = response;
        }
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const {showConsent, redirectTo} = res.response;
    if (showConsent) {
        res.setHeader("Content-Type", "text/html");
        res.send({template: "home/consent", locals: res.response});
        next();
    } else {
        res.redirect(302, redirectTo, next);
    }
};

export const addRoute = (server, route) => {
    server.get(
        `${route}/consent`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
