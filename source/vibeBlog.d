import vibe.d;

void errorHandler(HttpServerRequest req, HttpServerResponse res, HttpServerErrorInfo error)
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
    settings.port 		        = 8080;
    settings.hostName 		    = "1100110.in";
    settings.bindAddresses 	    = ["0.0.0.0"];
    settings.errorPageHandler 	= toDelegate(&errorHandler);

    auto router 		= new UrlRouter;
    router.get("/",     staticTemplate!"index.dt");  
    router.get("/hla",  staticTemplate!"hla.dt");
    router.get("*",     serveStaticFiles("./public"));
    
    listenHttp(settings, router);
}
