import koffie

def teste(req, res):
    res.set_body(b"junda!!!\n")

app = koffie.Server()

app.register_endpoint(b"/teste/", teste)

app.listen(32001, b"localhost")