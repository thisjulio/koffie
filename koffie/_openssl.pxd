cdef extern from "openssl/ec.h" nogil:
    ctypedef struct EC_KEY:
        pass
    cdef EC_KEY *EC_KEY_new_by_curve_name(int nid)

cdef extern from "openssl/ssl.h" nogil:
    cdef int SSL_OP_SINGLE_DH_USE "SSL_OP_SINGLE_DH_USE"
    cdef int SSL_OP_SINGLE_ECDH_USE "SSL_OP_SINGLE_ECDH_USE"
    cdef int SSL_OP_NO_SSLv2 "SSL_OP_NO_SSLv2"
    cdef int NID_X9_62_prime256v1 "NID_X9_62_prime256v1"
    cdef int SSL_FILETYPE_PEM "SSL_FILETYPE_PEM"
    cdef struct ssl_method_st:
        pass
    ctypedef ssl_method_st SSL_METHOD
    const SSL_METHOD* SSLv23_server_method()
    ctypedef struct ssl_st:
        pass
    ctypedef ssl_st SSL
    ctypedef struct SSL:
        pass
    ctypedef struct SSL_CTX:
        pass
    const SSL_METHOD* TLS_server_method()
    unsigned long SSL_CTX_set_options(SSL_CTX *ctx, unsigned long op)
    int SSL_library_init()
    SSL_CTX *SSL_CTX_new(const SSL_METHOD *meth)
    SSL *SSL_new(SSL_CTX *ctx)
    void SSL_free(SSL *ssl)
    int SSL_CTX_use_certificate_chain_file(SSL_CTX *ctx, const char *file)
    int SSL_CTX_use_PrivateKey_file(SSL_CTX *ctx, char *file, int type)
    long SSL_CTX_set_tmp_ecdh(SSL_CTX *ctx, char *parg)
    int SSL_CTX_check_private_key(const SSL_CTX *ctx)