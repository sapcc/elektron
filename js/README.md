# Elektron

Elektron is a tiny promise based JS client for OpenStack APIs. It handles the authentication, manages the session (re-authentication), implements the service discovery and offers the most important HTTP methods. Everything that Elektron knows and depends on is based solely on the token context it gets from Keystone.

### What it offers:

- Authentication
- Session with token context (service catalog, user data, scope) and automatic re-authentication
- HTTP Methods: GET, POST, PUT, PATCH, DELETE, HEAD
- Possibility to set headers on every request

### What it doesn't offer:

- Pre-defined API functions
- Knowledge about services
- Knowledge about request parameters and data
- Knowledge about response structure

## Installation

npm

```bash
$ npm install sapcc-elektron
```

## Usage

### Quick start

```js
import Elektron from "sapcc-elektron"

const elektron = Elektron("https://identity-3.qa-de-1.cloud.sap/v3", {
  userName: "your user name",
  password: "your password",
  userDomainName: "Default",
  scopeProjectId: "project id to which the token should be scoped",
})

elektron
  .service("compute")
  .get("/servers")
  .then((servers) => console.log(servers))
```

### Client

`Elektron(authEndpoint,authConf, options = {})`

- `authEndpoint` is a keystone endpoint URL

#### Auth conf properties

Authentication

- `userId: "12345"` (string) - user id
- `userName: "i0007"` (string) - user name. You should use userId or userName
- `userDomainId: "12345"` (string) - ID of the domain in which the user is defined
- `userDomainName: "Default"` (string) - name of the domain in which the user is defined. Use only userDomainId or userDomainName
- `password: "SECRET"` (string) - user password

Scope

- `scopeDomainId: "12345"` (string) - domain id for domain scoped token
- `scopeDomainName: "Default"` (string) - domain name for domain scoped token
- `scopeProjectId: "12345"` (string) - if provided, then all other scope parameters can be neglected
- `scopeProjectName: "demo"` (string) - project name
- `scopeProjectDomainName: "Default"` (string) - project domain name
- `scopeProjectDomainId: "12345"` (string) - project domain id
- `unscoped: false` (bool) - false to explicitly to get an unscoped token
- `token: "AUTH_TOKEN"` (string) - if token is provided and scope is not, then the client will validate this token and build the session based on the response data

**NOTE** automatic re-authentication is only possible if user credentials are provided (userId / userName, password, etc.)

Depending on the use case a different combination of the above parameters is necessary (see below for examples).

#### Options

- `headers: { "Content-Type": "application/json" }` (object) - custom headers
- `interfaceName: "public"` (string) - endpoint interface
- `region: "staging"` (string) - the region of the services endpoints
- `pathPrefix: "v2"` (string) - path prefix, e.g. to switch to another version
- `parseResponse: true` (bool) - parse response as json.
- `debug: true` (bool) - if true then logs debug output to console.

These options are valid for all services and requests (global options).

#### Examples

Authentication with user credentials

```js
const elektron = Elektron.client(
  "https://identity.test.com",
  {
    userName: "test",
    userDomainName: "Default",
    password: "devstack",
  },
  { region: "RegionOne", interfaceName: "public" }
)
```

Authentication with user credentials and domain scope

```js
const elektron = Elektron.client(
  "https://identity.test.com",
  {
    userName: "test",
    userDomainName: "Default",
    password: "devstack",
    scopeDomainName: "Default",
  },
  { region: "RegionOne", interfaceName: "public" }
)
```

Authentication with user credentials and project scope

```js
const elektron = Elektron.client(
  "https://identity.test.com",
  {
    userName: "test",
    userDomainName: "Default",
    password: "devstack",
    scopeProjectDomainName: "Default",
    scopeProjectName: "demo",
  },
  { region: "RegionOne", interfaceName: "public" }
)
```

Authentication with token

```js
const elektron = Elektron.client(
  "https://identity.test.com",
  {
    token: "OS_TOKEN",
  },
  { region: "RegionOne", interfaceName: "public" }
)
```

Authentication with token and scope

```js
const elektron = Elektron.client(
  "https://identity.test.com",
  {
    token: "OS_TOKEN",
    scopeProjectDd: "123456789",
  },
  { region: "RegionOne", interfaceName: "public" }
)
```

#### Client Methods

- `service(serviceNameOrType, options = {})` (string, object) - options can include  
  `headers, interfaceName, region, pathPrefix, parseResponse, debug`
- `token()` - returns a promise object which resolves to token
- `authToken()` - returns a promise object which resolves to the current auth token
- `logout()` - revokes the auth token

<!-- - `user_id`
- `user_name`
- `user_description`
- `user_domain_id`
- `user_domain_name`
- `domain_id`
- `domain_name`
- `project_id`
- `project_name`
- `project_parent_id`
- `project_domain_id`
- `project_domain_name`
- `expires_at` returns a Time object
- `expired?` returns true or false
- `issued_at` returns a Time object
- `catalog` returns the services catalog
- `service?(service_name_or_type)` returns true if catalog includes the service_name
- `roles` returns an array of role hashes ([{'id' => ID, 'name' => NAME}])
- `role_names` returns an array of role names
- `has_role?(role_name)` returns true or false
- `service_url(service_name_or_type, options = {})` options are :region and :interface
- `available_services_regions` returns an array of available regions
- `token` returns the token value (AUTH_TOKEN) -->

### Service

- `elektron.service(service_name, options = {})` (string,object) - returns a service based on the catalog

#### Options

- `headers: { "Content-Type": "application/json" }` (object) - custom headers
- `interfaceName: "public"` (string) - endpoint interface
- `region: "staging"` (string) - the region of the services endpoints
- `pathPrefix: "v2"` (string) - path prefix, e.g. to switch to another version
- `parseResponse: true` (bool) - parse response as json.
- `debug: true` (bool) - if true then logs debug output to console.

These options are valid only within the service (service options).

#### Examples

Identity service with public endpoint

```js
const identityService = elektron.service("identity", {
  interfaceName: "public",
})
```

Identity service with internal endpoint and prefix '/v3'

```js
const identityService = elektron.service("identity", { interfaceName: "internal", pathPrefix: "/v3")
```

Manila service with microversion headers

```js
const manilaService = elektron.service("share", { headers: { "X-OpenStack-Manila-API-Version": "2.15" })
```

### Request

- `service.head(path, options = {})` (string,object) - executes http HEAD method
- `service.get(path, options = {})` (string,object) - executes http GET method
- `service.post(path, values = {}, options = {})` (string,object,object) - executes http POST method
- `service.put(path, values = {}, options = {})` (string,object,object) - executes http PUT method
- `service.patch(path, values = {}, options = {})` (string,object,object) - executes http PATCH method
- `service.del(path, options = {})` (string,object) - executes http DELETE method

#### Options

- `headers: { "Content-Type": "application/json" }` (object) - custom headers
- `interfaceName: "public"` (string) - endpoint interface
- `region: "staging"` (string) - the region of the services endpoints
- `pathPrefix: "v2"` (string) - path prefix, e.g. to switch to another version
- `parseResponse: true` (bool) - parse response as json.
- `debug: true` (bool) - if true then logs debug output to console.

#### Response

The request returns different response objects depending on the `parseResponse` option. Under the hood, Elektron uses fetch. fetch returns a response object containing headers and other methods such as json. If `parseResponse` is set to `true` (default), then elektron automatically calls response.json(), which then returns a Promise object that parses the response as JSON. However, sometimes you want to access the response headers (identity: auth/token). In this case you have to set `parseResponse` to `false`.

Example:
`parseResponse: false`

```js
const elektron = Elektron.client("https://identity.test.com", {
  token: "OS_TOKEN",
})

elektron
  .service("identity")
  .post("/auth/token", { AUTH_OBJECT }, { parseResponse: false })
  .then(async (response) => {
    const authToken = response.headers.get("X-Subject-Token")
    const token = await response.json()
    return [authToken, token]
  })
```

`parseResponse: true` (default)

```js
const elektron = Elektron.client("https://identity.test.com", {
  token: "OS_TOKEN",
})

elektron
  .service("compute")
  .get("/servers")
  .then((servers) => {
    console.log(servers)
  })
  .catch((error) => console.error(error))
```

## Contributing

Contributors are welcome and must adhere to the [Contributor covenant code of conduct](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html).

Please submit issues/bugs and patches on the Elektron repository.

### Testing

```
git clone https://github.com/sapcc/elektron.git
cd elektron/js
npm install
npm test
```

## License

The npm is available as open source under the terms of the
Apache License Version 2.0, January 2004 http://www.apache.org/licenses/ - See [LICENSE](../APACHE-LICENSE) for details.
