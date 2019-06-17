from posix.time cimport timeval

# Libevent includes
cdef extern from "<evhttp.h>" nogil:
    # DEFINES
    cdef int HTTP_NOTFOUND "HTTP_NOTFOUND"
    cdef int HTTP_OK "HTTP_OK"
    # STRUCTS
    cdef struct evhttp
    cdef struct event_base
    cdef struct event
    cdef struct ev_ssize_t
    cdef struct evhttp_request
    cdef struct evbuffer
    cdef struct evkeyvalq
    cdef struct ev_uint16_t
    ctypedef int evutil_socket_t
    # FUNCTIONS
    cdef int evhttp_parse_query(const char *uri, evkeyvalq *headers)
    cdef int evbuffer_add(evbuffer *buf, const void *data, size_t datlen)
    cdef int evbuffer_add_printf(evbuffer *buf, const char *fmt, ...)
    cdef int evhttp_add_header(evkeyvalq *headers, const char *key, const char *value)
    cdef int event_add(event *ev, const timeval *timeout)
    cdef int event_base_loopexit(event_base *, const timeval *)
    cdef int evhttp_bind_socket(evhttp *http, const char *address, ev_uint16_t port)
    cdef int event_base_dispatch(event_base *)
    cdef int evhttp_set_cb(evhttp *http, const char *path, void (*cb)(evhttp_request *, void *), void *cb_arg)
    cdef const char *evhttp_request_get_uri(const evhttp_request *req)
    cdef const char *evhttp_find_header(const evkeyvalq *headers, const char *key)
    cdef event_base *event_base_new()
    cdef evhttp *evhttp_new(event_base *base)
    cdef evbuffer *evbuffer_new()
    cdef evbuffer *evhttp_request_get_input_buffer(evhttp_request *req)
    cdef size_t evbuffer_get_length(const evbuffer *buf)
    cdef ev_ssize_t evbuffer_copyout(evbuffer *buf, void *data_out, size_t datlen)
    cdef int evbuffer_remove(evbuffer *buf, void *data, size_t datlen)
    cdef evkeyvalq *evhttp_request_get_output_headers(evhttp_request *req)
    cdef event *evsignal_new(event_base *, evutil_socket_t, void (evutil_socket_t, short, void *), void *)
    cdef void evhttp_send_reply(evhttp_request *req, int code, const char *reason, evbuffer *databuf)
    cdef void evhttp_clear_headers(evkeyvalq *headers)
    cdef void evbuffer_free(evbuffer *buf)
    cdef void evhttp_set_gencb(evhttp *http, void (*cb)(evhttp_request *, void *), void *arg)
    cdef void evhttp_free(evhttp* http)
    cdef void event_base_free(event_base *)
    cdef void evhttp_send_error(evhttp_request *req, int error, const char *reason)