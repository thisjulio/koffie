from libc.signal cimport SIGINT
from libc.stdio cimport printf
from libc.stdlib cimport malloc, free
cimport koffie._libevent as libevent

ctypedef struct KFServer:
    libevent.event_base* base
    libevent.evhttp* http

ctypedef libevent.evhttp_request KFRequest

ctypedef libevent.evbuffer KFBuffer

cdef class Request:
    cdef KFRequest* _request

    def __cinit__(self):
        self._request = NULL

    cdef __setup__(self, KFRequest* request):
        self._request = request


cdef class Response:
    cdef KFRequest* _request
    cdef KFBuffer* _buffer

    def set_body(self,const char* body):
        libevent.evbuffer_add(self._buffer,<void*> body, len(body))

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

    def __cinit__(self):
        self._server = <KFServer*> malloc(sizeof(KFServer*))
        # Create a new event handler
        self._server.base = libevent.event_base_new()
        # Create a http server using that handler
        self._server.http = libevent.evhttp_new(self._server.base)
        # Add interrupt event
        self._interrupt = libevent.evsignal_new(self._server.base, SIGINT, quick_shutdown, self._server.base);
        libevent.event_add(self._interrupt, NULL);
    
    def listen(self, int port, bytes address):
        # Listen on address:port
        if (libevent.evhttp_bind_socket(self._server.http, address, <libevent.ev_uint16_t>port) != 0):
            pass #need to raise error!!!!
        libevent.event_base_dispatch(self._server.base)

    def register_endpoint(self,path,resolve_fn):
        libevent.evhttp_set_cb(self._server.http, path, register_endpoint_cb, <void *> resolve_fn)

    def __dealloc__(self):
        # Free up stuff
        libevent.evhttp_free(self._server.http)
        libevent.event_base_free(self._server.base)
        free(self._interrupt)
        free(self._server)


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

def test():
    for i in range(10):
        i**i

cpdef run_server():
    # cdef libevent.event_base *ebase = NULL
    # cdef libevent.evhttp *server = NULL
    
    # # Create a new event handler
    # ebase = libevent.event_base_new()

    # # Create a http server using that handler
    # server = libevent.evhttp_new(ebase)

    # # Add interrupt event
    # cdef libevent.event *interrupt = libevent.evsignal_new(ebase, SIGINT, quick_shutdown, ebase);
    # libevent.event_add(interrupt, NULL);

    # Limit serving GET requests
    #evhttp_set_allowed_methods (server, EVHTTP_REQ_GET)

    # Set a test callback, /testing
    # libevent.evhttp_set_cb(server, "/testing", testing, <void *> test)

    # # Set the callback for anything not recognized
    # libevent.evhttp_set_gencb(server, notfound, NULL)

    # # Listen locally on port 32001
    # if (libevent.evhttp_bind_socket(server, "127.0.0.1", <libevent.ev_uint16_t>32001) != 0):
    #     return 1

    # # Start processing queries
    # libevent.event_base_dispatch(ebase)

    # # Free up stuff
    # libevent.evhttp_free(server)

    # libevent.event_base_free(ebase)

    # return 0
    pass
