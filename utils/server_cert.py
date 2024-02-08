import socket
import ssl
import sys


def get_server_certificate(host: str, port: int) -> str:
    """connect to host:port and get the certificate it presents

    This is almost the same as `ssl.get_server_certificate`, but
    when opening the TLS socket, `server_hostname` is also provided.

    This retrieves the correct certificate for hosts using name-based
    virtual hosting.
    """
    if sys.version_info >= (3, 10):
        # ssl.get_server_certificate supports TLS SNI only above 3.10
        # https://github.com/python/cpython/pull/16820
        return ssl.get_server_certificate((host, port))

    context = ssl.SSLContext()

    with socket.create_connection((host, port)) as sock, context.wrap_socket(
        sock, server_hostname=host
    ) as ssock:
        cert_der = ssock.getpeercert(binary_form=True)

    assert cert_der
    return ssl.DER_cert_to_PEM_cert(cert_der)


def usage():
    print(
        "Usage: {sys.argv[0]} <url>"
        "\n Saves the certificate associated with <url> to a .pem file",
        file=sys.stderr,
    )


if __name__ == "__main__":
    if not sys.argv[1:]:
        usage()
        sys.exit(1)

    from urllib.parse import urlparse

    parsed = urlparse(sys.argv[1])
    host = parsed.hostname
    if not host:
        usage()
        sys.exit(1)

    port = parsed.port or 443

    cert = get_server_certificate(host, port)
    pem_out = f"{host}_{port}.pem"
    with open(pem_out, "w") as fh:
        fh.write(cert)
    print(f"Saved certificate to {pem_out}")
