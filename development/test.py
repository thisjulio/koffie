import koffie
import json

def teste(req, res):
    a = req.get_body()
    hw = json.dumps(dict(hello="world!"))
    res.set_header(b"Content-Type", b"application/json")
    res.set_body(hw.encode("utf8"))

app = koffie.Server(certificate_chain=b"cert.pem",private_key=b"key.pem")

app.register_endpoint(b"/teste/", teste)

app.listen_http(32001, b"localhost")
app.listen_https(32002, b"localhost")

app.start()