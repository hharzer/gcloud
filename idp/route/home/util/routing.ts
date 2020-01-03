import {addRoute as addShowLoginRoute} from "route/home/showLogin";
import {addRoute as addVerifyLoginRoute} from "route/home/verifyLogin";

export const addHomeRoute = (server, route) => {
    addShowLoginRoute(server, route);
    addVerifyLoginRoute(server, route);
};
