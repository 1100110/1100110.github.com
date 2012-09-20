module tor.tor;
import vibe.d;

enum hiddenWiki =  "kpvz7ki2v5agwt35.onion";
enum localTor   =  "127.0.0.1";
enum localTorPort = 8123;

static this()
{
    auto settings = new HttpServerSettings;
    settings.port = 1080;
    settings.hostName = "tor.1100110.in"; 
    settings.bindAddresses = ["0.0.0.0"];
    listenHttpReverseProxy(settings, "127.0.0.1", 8123);
}


HttpServerRequestDelegate torHandler()
{    

    static immutable string[] non_forward_headers = ["Content-Length", "Transfer-Encoding", "Content-Encoding"];
    static StrMapCI non_forward_headers_map;
    if( non_forward_headers_map.length == 0 )
        foreach( n; non_forward_headers )
            non_forward_headers_map[n] = "";

    void handleRequest(HttpServerRequest req, HttpServerResponse res)
    {
        string url = "http://"~req.params["url"];
        logInfo("Grabbing %s over tor...", url);
	
        auto cli = new HttpClient;
        cli.connect(url, 8123);

        auto cres = cli.request((HttpClientRequest creq){
            creq.method = req.method;
            creq.url = req.url;
            creq.headers = req.headers.dup;
            creq.headers["Host"] = url;
            creq.headers["X-Forwarded-Host"] = req.headers["Host"];
            creq.headers["X-Forwarded-For"] = req.peer;
            while( !req.bodyReader.empty )
                creq.bodyWriter.write(req.bodyReader, req.bodyReader.leastSize);
        });
   
        // copy the response to the original requester
        res.statusCode = cres.statusCode;

        // copy all headers that may pass from upstream to client
        foreach( n, v; cres.headers ){
            if( n !in non_forward_headers_map )
                res.headers[n] = v;
        }

        // copy the response body if any
        if( "Content-Length" !in cres.headers && "Transfer-Encoding" !in cres.headers ){
            res.writeVoidBody();
        } else {
        // enforce compatibility with HTTP/1.0 clients that do not support chunked encoding
        // (Squid and some other proxies)
        if( res.httpVersion == HttpVersion.HTTP_1_0 ){
            if( "Transfer-Encoding" in res.headers ) res.headers.remove("Transfer-Encoding");
                auto content = cres.bodyReader.readAll(1024*1024);
            res.headers["Content-Length"] = to!string(content.length);
            res.bodyWriter.write(content);
            return;
        }

        // by default, just forward the body using chunked encoding
        res.bodyWriter().write(cres.bodyReader);
        }
        assert(res.headerWritten);
    } 

    return &handleRequest;
}
