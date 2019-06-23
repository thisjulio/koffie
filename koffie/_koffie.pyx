from libc.signal cimport SIGINT
from libc.stdio cimport printf
from libc.stdlib cimport malloc, free
cimport koffie._libevent as libevent
cimport koffie._openssl as openssl

ctypedef struct KFServer:
    libevent.event_base* base
    libevent.evhttp* http
    libevent.evhttp* https

ctypedef libevent.evhttp_request KFRequest

ctypedef libevent.evbuffer KFBuffer

ctypedef libevent.evkeyvalq KFKeyVal
 
#https://github.com/ppelleti/https-example/blob/master/https-server.c

cdef class Request:
    cdef KFRequest* _request
    cdef char* _data_body

    def get_body(self):
        return self._data_body

    def __cinit__(self):
        self._request = NULL
        self._data_body = NULL

    cdef __setup__(self, KFRequest* request):
        self._request = request
        #Read data body
        cdef size_t data_body_len = 0
        cdef KFBuffer* buffer_body = libevent.evhttp_request_get_input_buffer(self._request)
        data_body_len = libevent.evbuffer_get_length(buffer_body)
        self._data_body = <char*> malloc(data_body_len + 1)
        self._data_body[data_body_len] = 0
        libevent.evbuffer_remove(buffer_body, self._data_body, data_body_len)
    
    def __dealloc__(self):
        free(self._data_body)



cdef class Response:
    cdef KFRequest* _request
    cdef KFBuffer* _buffer

    def set_body(self,const char* body):
        libevent.evbuffer_add(self._buffer,<void*> body, len(body))
    
    def set_header(self, const char* key, const char* value):
        libevent.evhttp_add_header(libevent.evhttp_request_get_output_headers(self._request), key, value)

    def __cinit__(self):
        self._request = NULL
        self._buffer = NULL

    cdef __setup__(self, KFRequest* request):
        self._request = request
        self._buffer = libevent.evbuffer_new()

    def __dealloc__(self):
        libevent.evbuffer_free(self._buffer)

cdef class Server:
    cdef KFServer* _server
    cdef libevent.event* _interrupt

    def __cinit__(self, const char* certificate_chain=NULL, const char* private_key=NULL):
        self._server = <KFServer*> malloc(sizeof(KFServer))
        # Create a new event handler
        self._server.base = libevent.event_base_new()
        
        # Create a http server using that handler
        self._server.http = libevent.evhttp_new(self._server.base)
        self._server.https = NULL

        # Shoud use https?
        cdef openssl.SSL_CTX *ctx
        cdef openssl.EC_KEY *ecdh
        if certificate_chain and private_key:
            # Create a http server using that handler
            self._server.https = libevent.evhttp_new(self._server.base)
            
            openssl.SSL_library_init()
            ctx = openssl.SSL_CTX_new(openssl.SSLv23_server_method());
            openssl.SSL_CTX_set_options(ctx, openssl.SSL_OP_SINGLE_DH_USE | openssl.SSL_OP_SINGLE_ECDH_USE | openssl.SSL_OP_NO_SSLv2)
            # Cheesily pick an elliptic curve to use with elliptic curve ciphersuites.
            #   * We just hardcode a single curve which is reasonably decent.
            #   * See http://www.mail-archive.com/openssl-dev@openssl.org/msg30957.html
            ecdh = openssl.EC_KEY_new_by_curve_name(openssl.NID_X9_62_prime256v1)
            if not ecdh:
                pass #die_most_horribly_from_openssl_error("EC_KEY_new_by_curve_name");
            if 1 != openssl.SSL_CTX_set_tmp_ecdh(ctx, <char*>ecdh):
                pass #die_most_horribly_from_openssl_error("SSL_CTX_set_tmp_ecdh");
            
            server_setup_certs(ctx, certificate_chain, private_key)
             
            # This is the magic that lets evhttp use SSL.
            libevent.evhttp_set_bevcb(self._server.https, bevcb, ctx);

        # Add interrupt event
        self._interrupt = libevent.evsignal_new(self._server.base, SIGINT, quick_shutdown, self._server.base);
        libevent.event_add(self._interrupt, NULL);
    
    def listen_http(self, int port, bytes address):
        # Listen http on address:port
        if (libevent.evhttp_bind_socket(self._server.http, address, <libevent.ev_uint16_t>port) != 0):
            pass #need to raise error!!!!

    def listen_https(self, int port, bytes address):
        # Listen http on address:port
        if (libevent.evhttp_bind_socket(self._server.https, address, <libevent.ev_uint16_t>port) != 0):
            pass #need to raise error!!!!
    
    def start(self):
        libevent.event_base_dispatch(self._server.base)

    def register_endpoint(self,path,resolve_fn):
        libevent.evhttp_set_cb(self._server.http, path, register_endpoint_cb, <void *> resolve_fn)
        if self._server.https != NULL:
            libevent.evhttp_set_cb(self._server.https, path, register_endpoint_cb, <void *> resolve_fn)

    def __dealloc__(self):
        # Free up stuff
        libevent.evhttp_free(self._server.http)
        
        if self._server.https != NULL:
            libevent.evhttp_free(self._server.https)
        
        libevent.event_base_free(self._server.base)
        free(self._interrupt)
        free(self._server)

cdef libevent.bufferevent* bevcb (libevent.event_base *base, void *arg) nogil:
    cdef libevent.bufferevent* r
    cdef openssl.SSL_CTX *ctx = <openssl.SSL_CTX*> arg
    r = libevent.bufferevent_openssl_socket_new(base, -1, libevent.SSL_new(ctx), libevent.BUFFEREVENT_SSL_ACCEPTING, libevent.BEV_OPT_CLOSE_ON_FREE)
    return r

cdef void server_setup_certs(openssl.SSL_CTX *ctx, const char *certificate_chain, const char *private_key):
    openssl.SSL_CTX_use_certificate_chain_file(ctx, certificate_chain)
    openssl.SSL_CTX_use_PrivateKey_file(ctx, private_key, libevent.SSL_FILETYPE_PEM)
    openssl.SSL_CTX_check_private_key(ctx)

cdef void quick_shutdown(libevent.evutil_socket_t _, short what, void *ctx) nogil:
    cdef libevent.event_base *evb = <libevent.event_base *>ctx
    printf("\nq-shutdown...\n")
    libevent.event_base_loopexit(evb, NULL)

cdef void notfound (libevent.evhttp_request *request, void *params) nogil:
    libevent.evhttp_send_error(request, libevent.HTTP_NOTFOUND, b"Not Found")

cdef void register_endpoint_cb(libevent.evhttp_request *request, void *privParams) nogil:
    with gil:
        kf_request = Request()
        kf_response = Response()
        kf_request.__setup__(request)
        kf_response.__setup__(request)
        (<object> privParams)(kf_request,kf_response)
        libevent.evhttp_send_reply(request, libevent.HTTP_OK, b"OK", kf_response._buffer)


cdef void testing(libevent.evhttp_request *request, void *privParams) nogil:
    cdef libevent.evbuffer *buffer = NULL
    cdef libevent.evkeyvalq *headers = NULL
    cdef const char *q = NULL

    with gil:
        (<object> privParams)()

    headers = <libevent.evkeyvalq*> malloc(sizeof(headers))

    # Parse the query for later lookups
    libevent.evhttp_parse_query(libevent.evhttp_request_get_uri(request), headers)

    # lookup the 'q' GET parameter 
    q = libevent.evhttp_find_header(headers, b"q")

    # Create an answer buffer where the data to send back to the browser will be appened
    buffer = libevent.evbuffer_new()
    libevent.evbuffer_add(buffer, b"coucou !", 8)
    libevent.evbuffer_add_printf(buffer, "%s", q)

    # Add a HTTP header, an application/json for the content type here
    libevent.evhttp_add_header(libevent.evhttp_request_get_output_headers(request), b"Content-Type", b"text/plain")

    # Tell we're done and data should be sent back
    libevent.evhttp_send_reply(request, libevent.HTTP_OK, b"OK", buffer)

    # Free up stuff
    libevent.evhttp_clear_headers(headers)

    libevent.evbuffer_free(buffer)

    free(headers)