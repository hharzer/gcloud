import * as moment from "moment";

export const setCookie = (res, cookie, attributes) => {
    const {path, expires, httpOnly} = attributes;
    if (path) {
        cookie["Path"] = path;
    }
    if (expires) {
        cookie["Expires"] = moment(expires).format("ddd, DD MMM YYYY HH:mm:ss [GMT]");
    }
    if (httpOnly) {
        cookie["HttpOnly"] = null;
    }
    const cookieContent = Object.entries(cookie)
        .map(([attribute, value]) => (value ? `${attribute}=${value}` : attribute))
        .join("; ");
    res.header("Set-Cookie", cookieContent);
};

export const deleteCookie = (res, cookieName) => {
    const attributes = {expires: moment().subtract(1, "year")};
    const cookie = {[cookieName]: "deleted"};
    setCookie(res, cookie, attributes);
};

export const cookieParser = () => {
    return (req, res, next) => {
        const cookiesContent = req.header("Cookie");
        if (cookiesContent) {
            const cookiesEntries = cookiesContent
                .split("; ")
                .map((cookie) => cookie.split("="));
            const cookies = Object.fromEntries(cookiesEntries);
            req.cookies = cookies;
        }
        next();
    };
};
