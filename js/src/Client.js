import fetch from "cross-fetch"

const DEFAULT_HEADERS = { "Content-Type": "application/json" }

/**
 * This function checks the response status code and throws an error if code < 200 or code >= 300.
 * @param {promise} response
 * @returns
 */
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

/**
 * Handle the response and parse it as json if parseResponse option is set.
 * @param {promise} response
 * @param {object} options parseResponse
 * @returns
 */
const handleResponse = async (response, options) => {
  return options?.parseResponse ? response.json() : response
}

/**
 *
 * @param {object} options headers, url, pathPrefix, parseResponse
 */
function Client(options = {}) {
  this.headers = { ...options.headers }
  this.url = options.url
  this.pathPrefix = options.pathPrefix
  this.parseResponse = options.parseResponse
}

/**
 * Build url based on instance options and given parameters
 * @param {string} url a absolute url or a path (if this.url is set)
 * @param {object} options can contain pathPrefix
 * @returns an absolute url
 */
Client.prototype.getUrl = function (url, options = {}) {
  if (url.indexOf("http") === 0) return url
  let base = this.url
  // pathPrefix can be overwritten on every request
  const pathPrefix = options.hasOwnProperty("pathPrefix")
    ? options.pathPrefix
    : this.pathPrefix

  if (pathPrefix) {
    base = new URL(pathPrefix, base).toString()
  }
  let endpoint = new URL(base + "/" + url)
  // replace double slashes with single slash
  endpoint = endpoint.origin + endpoint.pathname.replace(/\/\/+/g, "/")

  return endpoint
}

/**
 * Implements a static function for HEAD
 * @param {string} url
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.head = function (url, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "HEAD",
  }).then(checkStatus)
}

/**
 * Implements a static function for GET
 * @param {string} url
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.get = function (url, options = {}) {
  // console.log(url, { headers: { ...DEFAULT_HEADERS, ...options.headers } })
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "GET",
  })
    .then(checkStatus)
    .then((response) =>
      handleResponse(response, { parseResponse: options.parseResponse })
    )
}

/**
 * Implements a static function for DELETE
 * @param {string} url
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.del = function (url, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "DELETE",
  }).then(checkStatus)
}

/**
 * Implements a static function for POST
 * @param {string} url
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.post = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "POST",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then((response) =>
      handleResponse(response, { parseResponse: options.parseResponse })
    )
}

/**
 * Implements a static function for PATCH
 * @param {string} url
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.patch = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "PATCH",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then(handleResponse)
}

/**
 * Implements a static function for PUT
 * @param {string} url
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
Client.put = function (url, values, options = {}) {
  return fetch(url, {
    headers: { ...DEFAULT_HEADERS, ...options.headers },
    method: "PUT",
    body: JSON.stringify(values),
  })
    .then(checkStatus)
    .then((response) =>
      handleResponse(response, { parseResponse: options.parseResponse })
    )
}

/**
 * Implements instance function for HEAD
 * @param {string} url absolute url or relative path
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.head = function (url, options = {}) {
  return Client.head(this.getUrl(url, options), {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

/**
 * Implements instance function for GET
 * @param {string} url absolute url or relative path
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.get = function (url, options = {}) {
  return Client.get(this.getUrl(url, options), {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

/**
 * Implements instance function for DELETE
 * @param {string} url absolute url or relative path
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.del = function (url, options = {}) {
  return Client.del(this.getUrl(url, options), {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

/**
 * Implements instance function for POST
 * @param {string} url absolute url or relative path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.post = function (url, values, options = {}) {
  return Client.post(this.getUrl(url, options), values, {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

/**
 * Implements instance function for PATCH
 * @param {string} url absolute url or relative path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.patch = function (url, values, options = {}) {
  return Client.patch(this.getUrl(url, options), values, {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

/**
 * Implements instance function for PUT
 * @param {string} url absolute url or relative path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns promise
 */
Client.prototype.put = function (url, values, options = {}) {
  return Client.put(this.getUrl(url, options), values, {
    headers: { ...this.headers, ...options.headers },
    parseResponse: options.hasOwnProperty("parseResponse")
      ? options.parseResponse
      : this.parseResponse,
  })
}

export default Client
