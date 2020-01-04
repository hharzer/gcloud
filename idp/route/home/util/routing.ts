import {addRoute as addShowLoginRoute} from "route/home/showLogin";
import {addRoute as addVerifyLoginRoute} from "route/home/verifyLogin";
import {addRoute as addShowConsentRoute} from "route/home/showConsent";
import {addRoute as addConfirmConsentRoute} from "route/home/confirmConsent";

export const addHomeRoute = (server, route) => {
    addShowLoginRoute(server, route);
    addVerifyLoginRoute(server, route);
    addShowConsentRoute(server, route);
    addConfirmConsentRoute(server, route);
};
