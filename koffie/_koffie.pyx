from libc.stdlib cimport malloc, free
cimport _libevent as libevent

cdef void notfound (libevent.evhttp_request *request, void *params) nogil:
    libevent.evhttp_send_error(request, libevent.HTTP_NOTFOUND, "Not Found")

cdef void testing(libevent.evhttp_request *request, void *privParams) nogil:
    cdef libevent.evbuffer *buffer
    cdef libevent.evkeyvalq *headers = <libevent.evkeyvalq*> malloc(sizeof(headers))
    cdef const char *q
    # Parse the query for later lookups
    libevent.evhttp_parse_query(libevent.evhttp_request_get_uri(request), headers)

    # lookup the 'q' GET parameter 
    q = libevent.evhttp_find_header(headers, "q")

    # Create an answer buffer where the data to send back to the browser will be appened
    buffer = libevent.evbuffer_new()
    libevent.evbuffer_add(buffer, "coucou !", 8)
    libevent.evbuffer_add_printf(buffer, "%s", q)

    # Add a HTTP header, an application/json for the content type here
    libevent.evhttp_add_header(libevent.evhttp_request_get_output_headers(request), "Content-Type", "text/plain")

    # Tell we're done and data should be sent back
    libevent.evhttp_send_reply(request, libevent.HTTP_OK, "OK", buffer)

    # Free up stuff
    libevent.evhttp_clear_headers(headers)

    libevent.evbuffer_free(buffer)

    free(headers)

cpdef run_server():
    cdef libevent.event_base *ebase
    cdef libevent.evhttp *server

    # Create a new event handler
    ebase = libevent.event_base_new()

    # Create a http server using that handler
    server = libevent.evhttp_new(ebase)

    # Limit serving GET requests
    #evhttp_set_allowed_methods (server, EVHTTP_REQ_GET)

    # Set a test callback, /testing
    libevent.evhttp_set_cb(server, "/testing", testing, NULL)

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
