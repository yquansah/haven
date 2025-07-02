## Kubernetes Auth

Kubernetes auth is not as complicated as it seems. Basically, the api server takes care of authn and authz.

### Authn

For authn, the api server can be configured to use a variety of authentication methods. The most common are:

- Basic Auth
- Token Auth
- Client Cert Auth
- Service Account Auth
- OpenID Connect Auth

Client cert authn is probably the easiest as it usually comes built in with most distributions. But for our purposes and to integrate with Oauth2.0 providers, we will use OpenID Connect for authentication.

### Authz

For authz, the api server can be configured to use a variety of authorization methods. The most common are:

- RBAC
- ABAC
- Webhook
- Node
- AlwaysDeny
- AlwaysAllow

RBAC is the most common authorization method, because it is built into the api server, and we do not have to rely on external systems for authorization of a request.
