import {addRoute as addIndexRoute} from "route/home/index";
import {addRoute as addLoginRoute} from "route/home/login";
import {addRoute as addCallbackRoute} from "route/home/callback";
import {addRoute as addErrorRoute} from "route/home/error";

export const addHomeRoute = (server, route) => {
    addIndexRoute(server, route);
    addLoginRoute(server, route);
    addCallbackRoute(server, route);
    addErrorRoute(server, route);
};
