import fetch from "cross-fetch"

const DEFAULT_HEADERS = { "Content-Type": "application/json" }

const checkStatus = (response) => {
  if (response.status >= 200 && response.status < 300) {
    return response
  } else {
    return response.text().then((message) => {
      var error = new Error(message || response.statusText || response.status)
      error.statusCode = response.status
      // throw error
      return Promise.reject(error)
    })
  }
}

const handleResponse = async (response) => {
  return response
}

function Client(options = {}) {
  this.headers = { ...options.headers }
  this.url = options.url
}

Client.prototype.getUrl = function (url) {
  if (url.indexOf("http") === 0) return url
  return new URL(url, this.url).toString()
}

Client.head = function (url, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "HEAD",
  })
    .then(checkStatus)
    .then(handleResponse)
}

Client.get = function (url, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
  })
    .then(checkStatus)
    .then(handleResponse)
}

Client.del = function (url, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "DELETE",
  }).then(checkStatus)
}

Client.post = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "POST",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then(handleResponse)
}

Client.patch = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "PATCH",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then(handleResponse)
}

Client.put = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "PUT",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then(handleResponse)
}

Client.prototype.head = function (path, options = {}) {
  return Client.head(this.getUrl(url), {
    headers: { ...this.headers, ...options.headers },
  })
}

Client.prototype.get = function (url, options = {}) {
  return Client.get(this.getUrl(url), {
    headers: { ...this.headers, ...options.headers },
  })
}

Client.prototype.del = function (url, options = {}) {
  return Client.del(this.getUrl(url), {
    headers: { ...this.headers, ...options.headers },
  })
}

Client.prototype.post = function (url, values, options = {}) {
  return Client.post(this.getUrl(url), values, {
    headers: { ...this.headers, ...options.headers },
  })
}

Client.prototype.patch = function (url, values, options = {}) {
  return Client.patch(this.getUrl(url), values, {
    headers: { ...this.headers, ...options.headers },
  })
}

Client.prototype.put = function (url, values, options = {}) {
  return Client.put(this.getUrl(url), values, {
    headers: { ...this.headers, ...options.headers },
  })
}

export default Client
