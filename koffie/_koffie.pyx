from libc.signal cimport SIGINT
from libc.stdio cimport printf
from libc.stdlib cimport malloc, free
cimport koffie._libevent as libevent

cdef void quick_shutdown(libevent.evutil_socket_t _, short what, void *ctx) nogil:
    cdef libevent.event_base *evb = <libevent.event_base *>ctx
    printf("\nq-shutdown...\n")
    libevent.event_base_loopexit(evb, NULL)

cdef void notfound (libevent.evhttp_request *request, void *params) nogil:
    libevent.evhttp_send_error(request, libevent.HTTP_NOTFOUND, b"Not Found")

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
    cdef libevent.event_base *ebase = NULL
    cdef libevent.evhttp *server = NULL
    
    # Create a new event handler
    ebase = libevent.event_base_new()

    # Create a http server using that handler
    server = libevent.evhttp_new(ebase)

    # Add interrupt event
    cdef libevent.event *interrupt = libevent.evsignal_new(ebase, SIGINT, quick_shutdown, ebase);
    libevent.event_add(interrupt, NULL);

    # Limit serving GET requests
    #evhttp_set_allowed_methods (server, EVHTTP_REQ_GET)

    # Set a test callback, /testing
    libevent.evhttp_set_cb(server, "/testing", testing, <void *> test)

    # Set the callback for anything not recognized
    libevent.evhttp_set_gencb(server, notfound, NULL)

    # Listen locally on port 32001
    if (libevent.evhttp_bind_socket(server, "127.0.0.1", <libevent.ev_uint16_t>32001) != 0):
        return 1

    # Start processing queries
    libevent.event_base_dispatch(ebase)

    # Free up stuff
    libevent.evhttp_free(server)

    libevent.event_base_free(ebase)

    return 0
