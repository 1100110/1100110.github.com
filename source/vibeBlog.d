import vibe.d;
import tor.tor; 

void error(HttpServerRequest req, HttpServerResponse res, HttpServerErrorInfo error)
{
    res.renderCompat!("error.dt",
        HttpServerRequest, "req",
        HttpServerErrorInfo,"error")
        (Variant(req), Variant(error));
}

static this()
{ 
    //setLogLevel(LogLevel.Debug);

    auto settings 		        = new HttpServerSettings;
    settings.port 		        = 80;
    settings.hostName 		    = "1100110.in";
    settings.bindAddresses 	    = ["127.0.0.1"];
    settings.errorPageHandler 	= toDelegate(&error);

    auto router 		    = new UrlRouter;
    router.get("/",         staticTemplate!"index.dt");  
    router.get("*",         serveStaticFiles("./public"));
    router.get("/tor/:url", torHandler());   
    
    listenHttp(settings, router);
}
