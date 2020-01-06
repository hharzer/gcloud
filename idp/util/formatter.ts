import {renderFile} from "pug";

export const formatHtml = (view) => {
    return (req, res, {template, locals}) => {
        try {
            const options = {cache: false, compileDebug: false};
            return renderFile(`${view}/${template}.pug`, {...options, ...locals});
        } catch (error) {
            res.status(500);
            res.header("Content-Type", "application/json");
            return JSON.stringify({code: "RenderingError", message: error.message});
        }
    };
};
