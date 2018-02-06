# Elektron
Elektron is a tiny Ruby client for OpenStack APIs. It handles the authentication, manages the session (re-authentication), implements the service discovery and offers the most important HTTP methods. Everything that Elektron knows and depends on is based solely on the token context it gets from Keystone.

Unlike the well-known and widely used Fog Elektron does not define functions for individual API calls and does not evaluate the response. Elektron only provides the infrastructure to enable individual API calls.

### What it offers:
  * Authentication
  * Session with token context (service catalog, user data, scope) and automatic re-authentication
  * HTTP Methods: GET, POST, PUT, PATCH, DELETE, COPY, HEAD and OPTIONS
  * Possibility to set headers and body on every request
  * Mapping of response data to objects
  * A middleware based request architecture

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
  scope_domain_name: 'Default'
}, { region: 'RegionOne', interface: 'public'})

identity = client.service('identity', path_prefix: 'V3')
identity.get('auth/projects').map_to('body.projects' => OpenStruct)
```

### Client
` Elektron.client(auth_conf, options = {}) `

#### Auth Conf Parameters

* `:url` Keystone Endpoint URL
* `:user_id`
* `:user_name`
* `:user_domain_id` ID of the domain in which the user is defined
* `:user_domain_name` name of the domain in which the user is defined
* `:password`
* `:scope_domain_id`
* `:scope_domain_name`
* `:scope_project_id` if provided, then all other scope parameters can be neglected
* `:scope_project_name`
* `:scope_project_domain_name`
* `:scope_project_domain_id`
* `scope: 'unscoped'` to explicitly to get an unscoped token
* `:token_context`
* `:token` if token is provided and token_context is not, then the client will validate this token and build the session based on the response data

**NOTE** automatic re-authentication is only possible if user credentials are provided (user_id / user_name, password, etc.)

Depending on the use case a different combination of the above parameters is necessary (see below for examples).

#### Options

* `:headers` custom headers, default: `{}`
* `:interface` endpoint interface, default: `'internal'`
* `:region` the region of the services endpoints
* `:http_client` options for HTTP client, default:
  ```
  {
    open_timeout: 10,
    read_timeout: 60,
    keep_alive_timeout: 60,
    verify_ssl: false
  }
  ```

* `:debug` if true then logs debug output to console.  
  **WARNING** This method opens a serious security hole. Never use this method in production code.  
  Default: `false`

These options are valid for all services and requests (global options).

#### Examples

Authentication with user credentials
```
client = Elektron.client({
  url: 'https://identity.test.com',
  user_name: 'test',
  user_domain_name: 'Default',
  password: 'devstack'
}, { region: 'RegionOne', interface: 'public'})
```

Authentication with user credentials and domain scope
```
client = Elektron.client({
  url: 'https://identity.test.com',
  user_name: 'test',
  user_domain_name: 'Default',
  password: 'devstack',
  scope_domain_name: 'Default'
}, { region: 'RegionOne', interface: 'public'})
```

Authentication with user credentials and project scope
```
client = Elektron.client({
  url: 'https://identity.test.com',
  user_name: 'test',
  user_domain_name: 'Default',
  password: 'devstack',
  scope_project_domain_name: 'Default',
  scope_project_name: 'demo'
}, { region: 'RegionOne', interface: 'public'})
```

Authentication with token
```
client = Elektron.client({
  url: 'https://identity.test.com',
  token: 'OS_TOKEN'
}, { region: 'RegionOne', interface: 'public'})
```

Authentication with token and scope
```
client = Elektron.client({
  url: 'https://identity.test.com',
  token: 'OS_TOKEN',
  scope_project_id: '123456789'
}, { region: 'RegionOne', interface: 'public'})
```

Authentication with token context
```
client = Elektron.client({
  url: 'https://identity.test.com',
  token: 'OS_TOKEN',
  token_context: {"token" => {...}}
}, { region: 'RegionOne', interface: 'public'})
```

#### Client Methods
* `middlewares`, holds the stack of middlewares
* `service(service_name_or_type, options = {})`, options can include       
  `:headers, :interface, :region, :path_prefix, :client, :debug`
* `is_admin_project?` returns true if current scope project has the flag admin
* `user_id`
* `user_name`
* `user_description`
* `user_domain_id`
* `user_domain_name`
* `domain_id`
* `domain_name`
* `project_id`
* `project_name`
* `project_parent_id`
* `project_domain_id`
* `project_domain_name`
* `expires_at` returns a Time object
* `expired?` returns true or false
* `issued_at` returns a Time object
* `catalog` returns the services catalog
* `service?(service_name_or_type)` returns true if catalog includes the service_name
* `roles` returns an array of role hashes ([{'id' => ID, 'name' => NAME}])
* `role_names` returns an array of role names
* `has_role?(role_name)` returns true or false
* `service_url(service_name_or_type, options = {})` options are :region and :interface
* `available_services_regions` returns an array of available regions
* `token` returns the token value (AUTH_TOKEN)

### Service

`client.service(service_name, options = {})`

#### Service Options

Accepts all client options (global options) plus one more option:
* `:path_prefix` path prefix which is used for all requests. For example, you can set the API version to be used by specifying `path_prefix: '/v2.0'`

  **Important:** if path_prefix is not provided the path of service url is is used. If path_prefix starts with a slash (`/`), then the path of service url is ignored. Otherwise the path_prefix will be appended to the original service url path.

  Example: `client.service('identity', path_prefix: '/v3').get('users')`
  => path is `/v3/users`

These options are valid only within the service (service options).

#### Examples

Identity service with public endpoint
```
client.service('identity', interface: 'public')
```

Identity service with internal endpoint and prefix '/v3'
```
client.service('identity', interface: 'internal', path_prefix: '/v3')
```

Manila service with microversion headers
```
client.service('share', headers: { 'X-OpenStack-Manila-API-Version' => '2.15'})
```

### Request

`service.HTTP_METHOD(path, parameters = {}, options = {}, &block)`
* parameters: are URL parameters. Example: path = `'auth/projects'` with parameter `{ name: 'test' }` results in `'/auth/projects?name=test'`
* options: `:path_prefix`, `:region`, `:interface`, `:headers`, `:http_client` and `:debug`  
  These options are valid only within the request (request options).

**IMPORTANT** if the path contains either the symbol `:project_id` or `:tenant_id` then it is mapped
to the project_id of the current token scope.  
Example: `service.get('projects/:project_id')` results in `'projects/PROJECT_ID'`

#### Request Response

The response object of the request returns a wrapped net/http response object. It has the following methods:

* `body` returns the body as JSON.
* `header` makes it possible to access response headers.   
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
* `copy` Accepts path, url parameters and options
  ```
  swift_service.copy('my_account/container1/object1', headers: { 'Destination' => '/target_container/target_path'})
  ```  
* `head` Accepts path, url parameters and options
  ```
  swift_service.head('my_account/container1')
  ```

### Mapping

Elektron provides a default middleware (see below) that handles the API response. This middleware implements the `map_to` method which maps the response body to an object or to an array of objects. It requires two parameters **key** and **class**. The key consists of individual hierarchy tokens connected by a dot. Where body denotes the beginning ROOT.  

```
class User < OpenStruct; end

client = Elektron.client(auth_conf, options)
identity = client.service('identity', path_prefix: 'V3')

users = identity.get('users').map_to('body.users' => User)
```

Under the hood `map_to` calls Class.new(attributes). Sometimes you want to pass more parameters than just the attributes. For this case, `map_to` accepts a block in which you can arbitrarily create the object to be mapped.

```
class User
  def initialize(name, attributes); end
end

client = Elektron.client(auth_conf, options)
identity = client.service('identity')

users = identity.get('users').map_to('body.users') do |attributes|
  User.new('user1', attributes)
end
```

Or if you want to reuse the mapping

```
class User
  def initialize(name, attributes); end
end

user_map = proc { |attributes| User.new('test_user', attributes) }

client = Elektron.client(auth_conf, options)
identity = client.service('identity')

users = identity.get('users').map_to('body.users', &user_map)
```

### Middlewares
The entire request/response process in Elektron is based on middlewares. Middlewares are small applications (apps) that are called in succession. Each middleware has access to all request data and can manipulate it. It can also access the response data in the same way as it passes through all middleware on the way back.

The order of middlewares is important! Because it can be important to change request data or response data before they are passed on to the next app. For this, Elektron manages a stack of classes that implement the middlewares. Each of these classes must offer at least two methods, `initialize` and `call`. If such a class is instantiated, it gets a parameter reference to the next app in the stack. The `call` method receives the request data as parameter and must return the response. This provides the possibility to manipulate the request data as well as the response data during the execution of the call method. Most of the time you only want to edit data in one direction with a middleware.

Example for a middleware:
```ruby
  class NewMiddleware < ::Elektron::Middlewares::Base
    def initialize(next_middleware = nil)
      @next_middleware = next_middleware
    end

    def call(request_data)
      # add some params to request_data
      request_data.params['test'] = true
      # call next app
      response = @next_middleware.call(request_data)
      # now we could manipulate the response data
      # return response
      response
    end
  end
```

**Request Data** is a container object that responds to the following methods:
* `service_name`, the name of current service
* `token`
* `service_url`, url to be used for request
* `project_id`, project id from token context
* `http_method`, to be used for request
* `path`
* `params`, url params
* `options`, a hash with keys `:headers`, `:interface`, `:region`, `:http_client`, `:debug`
* `data`, request body
* `cache`, a reference to a variable that is kept in the service. It is used to store values across all requests

**Response** is a container object that responds to the following methods:
* `body`, response body
* `header`, response headers
* `service_name`, name of current service
* `http_method`, method used for request
* `url`, url used for request

#### Stack

The stack maintains a list of middlewares. It offers a variety of methods that allow you to add new apps, remove or replace existing ones. In particular, this can be used to influence the order of app processing. The order of the middlwares plays a special role, since each app can manipulate the request data before it is passed on to the other app in the stack.

Methods:
* `add`, requires a name and accepts two options `before` and `after`. Without options it adds a middleware to the stack on top (outside).
* `remove`, requires a name
* `replace`, replaces a middleware with another on the same position.
* `execute`, runs all middlewares at a time in the given order

![Middleware Stack](docs/elektron_middleware_stack.pdf?raw)

A request is started by a service with the external app and continues to be passed on to the inner app until it is finally sent to the API. Since the call method of the middlewares always has to return a response, the innermost app starts the response and passes it further through the chain of middlwares.


Example:
```ruby

class PrettyDebug < Elektron::Middlewares::Base
  def call(request_context)
    unless request_context.options[:debug]
      return @next_middleware.call(request_context)
    end
    # Green
    Rails.logger.debug("\033[32m\033[1m################ Elektron: Http Client #############\033[22m")
    response = @next_middleware.call(request_context)
    Rails.logger.debug("\033[0m")
    response
  end
end

client = Elektron.client({
  url: 'https://identity.test.com',
  user_name: 'test',
  user_domain_name: 'Default',
  password: 'devstack',
  scope_domain_name: 'Default'
}, { region: 'RegionOne', interface: 'public'})

client.middlewares.add(PrettyDebug, after: HttpRequestPerformer)
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
