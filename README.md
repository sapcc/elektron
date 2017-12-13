# Elektron
Elektron is a tiny client for OpenStack APIs. It handles the authentication, manages the session (reauthentication), implements the service discovery and offers the most important HTTP methods. Everything that Elektron knows and depends on is based solely on the token context it gets from Keystone.

### What it offers:
  * Authentication
  * Session with token context (service catalog, user data, scope) and automatic reauthentication
  * HTTP Methods: GET, POST, PUT, PATCH, DELETE and OPTIONS
  * Possibility to set headers and body on every request
  * Mapping of response data to objects

### What it doesn't offer:
  * Pre-defined API functions
  * Knowledge about services
  * Knowledge about request parameters and data
  * Knowledge about response structure

Elektron is just a client that makes it easy to communicate with OpenStack APIs. It does not add its own logic.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'elektron'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install elektron
```

## Usage

### Quick start
```
client = Elektron.client({
  url: 'https://identity.test.com',
  user_name: 'test',
  user_domain_name: 'Default',
  password: 'test',
  domain_name: 'Default'
}, { region: 'RegionOne', interface: 'public'})

identity = client.service('identity', path_prefix: 'V3')
identity.get('auth/projects').map_to('body.projects' => OpenStruct)
```

### Client
` Elektron.client(AUTH_CONF, options = {}) `

#### Auth Conf Parameters
* `:url`  
  Keystone Endpoint URL
* `:user_id`
* `:user_name`
* `:user_domain_id`  
  ID of the domain in which the user is defined
* `:user_domain_name`  
  name of the domain in which the user is defined
* `:password`
* `:scope_domain_id`
* `:scope_domain_name`
* `:scope_project_id`  
  if given, then all other scope parameters can be neglected
* `:scope_project_name`
* `:scope_project_domain_name`
* `:scope_project_domain_id`
* `scope: 'unscoped'`  
  to explicitly to get an unscoped token
* `:token_context`
* `:token`  
  If token is given and token_context not then the client will validate this token and build the session based on the response data

**NOTE** automatic re-authentication is only possible if user credentials are provided (user_id / user_name, password, etc.)

#### Client Options

* `:headers`  
  Custom headers
  Default: `{}`
* `:interface`
  Endpoint interface  
  Default: `'internal'`
* `:region`  
  Region of services endpoints
* `:client`
  Options for HTTP client  
  Default: `{
    open_timeout: 10,
    read_timeout: 60,
    keep_alive_timeout: 60,
    verify_ssl: false
  }`
* `:debug`  
  If true then logs debug output to console.  
  **WARNING** This method opens a serious security hole. Never use this method in production code.  
  Default: `false`

These options are valid for all services and requests (global options).

### Service

`client.service(SERVICE_NAME, options = {})`

#### Service Options

Accepts all client options (global options) plus one more option:
* `:path_prefix`  
  Path prefix which is used for all requests.  
  For example, you can set the API version to use by `path_prefix: 'V2.0'`

These options are valid only within the service (service options).

### Request

`service.HTTP_METHOD(PATH, parameters = {}, options = {}, &block)`
* parameters: are url parameters. Example: path = 'auth/projects' and parameters are { name: 'test' } results in `'/auth/projects?name=test'`
* options: `path_prefix`, `:region`, `:interface` and `headers`  
  These options are valid only within the request (request options).

**IMPORTANT** if path contains a `:project_id`or `:tenant_id` so it is mapped
to the project_id of the current token scope.  
Example: `service.get('projects/:project_id')` results in `'projects/PROJECT_ID'`

#### Request Response

The response object of request returns a wrapped net/http response object. It has the following methods:

* `body` returns the body as JSON.
* `[]` make it possible to access response headers.   
* `map_to` maps the response to an object or an array of objects.


#### Available Methods
* `get` Accepts path, url parameters and options.  
  ```
  identity_service.get('auth/projects', name: 'test', interface: 'public')
  ```
* `post` Accepts path, url parameters, options and block.
  ```
  identity_service.post('projects') do  
    {"project" => PROJECT_DATA}
  end
  ```

* `delete` Accepts path, url parameters and options.
  ```
  identity_service.delete("projects/#{PROJECT_ID}")
  ```
* `put` Accepts path, url parameters, options and block.
  ```
  identity_service.put("projects/#{PROJECT_ID}") do
    { "project" => PROJECT_DATA }
  end
  ```
* `patch` Accepts path, url parameters, options and block.
  ```
  identity_service.patch("projects/#{PROJECT_ID}") do
    { "project" => PROJECT_DATA }
  end
  ```
* `options` Accepts path, url parameters and options
  ```
  identity_service.options('projects')
  ```


### Mapping

Elektron provides a `map_to` method which maps the response body to an object or to an array of objects. It requires two parameters **key** and **class**. The key consists of individual hierarchy tokens connected by a dot. Where body denotes the beginning ROOT.  

```
class User < OpenStruct; end

client = Elektron.client(auth_conf, options)
identity = client.service('identity', path_prefix: 'V3')

users = identity.get('users').map_to('body.users' => User)
```

## Contributing
Contributors are welcome and must adhere to the Contributor covenant code of conduct.

Please submit issues/bugs and patches on the Elektron repository.

### Testing
```
git clone https://github.com/sapcc/elektron.git
cd elektron
bundle install
bundle exec rspec
```

## License
The gem is available as open source under the terms of the
Apache License Version 2.0, January 2004 http://www.apache.org/licenses/ - See [LICENSE](APACHE-LICENSE) for details.
