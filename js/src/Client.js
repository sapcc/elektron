import fetch from "cross-fetch"

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
const handleResponse = async (response, parseResponse) => {
  return parseResponse && response.json ? response.json() : response
}

/**
 * Build url based on instance options and given parameters
 * @param {string} base a absolute url
 * @param {string} path
 * @param {object} options can contain pathPrefix
 * @returns an absolute url
 */
const buildURL = function (base, path, pathPrefix) {
  if (path.indexOf("http") === 0) return path

  if (pathPrefix) {
    base = new URL(pathPrefix, base).toString()
  }

  let endpoint = new URL(base + "/" + path)
  // replace double slashes with single slash
  endpoint = endpoint.origin + endpoint.pathname.replace(/\/\/+/g, "/")

  return endpoint
}

const request = (method, path, options) => {
  const url = buildURL(options.host, path, options.pathPrefix)
  const body = options.body && JSON.stringify(options.body)

  if (options.debug) {
    console.debug(
      "Debug: url = ",
      url,
      ", headers = ",
      JSON.stringify({ ...options.headers }, null, 2),
      ", body = ",
      body,
      ", parseResponse = ",
      options.parseResponse
    )
  }

  return fetch(url, {
    headers: { ...options.headers },
    method,
    body,
  })
    .then(checkStatus)
    .then((response) => handleResponse(response, options.parseResponse))
}

/**
 * Implements a static function for HEAD
 * @param {string} path
 * @param {object} options parseResponse, pathPrefix, headers, host
 * @returns
 */
export const head = (path, options = {}) => request("HEAD", path, options)

/**
 * Implements a static function for GET
 * @param {string} path
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
export const get = (path, options = {}) => request("GET", path, options)

/**
 * Implements a static function for DELETE
 * @param {string} path
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
export const del = (path, options = {}) => request("DELETE", path, options)

/**
 * Implements a static function for POST
 * @param {string} path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
export const post = (path, values, options = {}) =>
  request("POST", path, { ...options, body: values })

/**
 * Implements a static function for PATCH
 * @param {string} path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
export const patch = (path, values, options = {}) =>
  request("PATCH", path, { ...options, body: values })

/**
 * Implements a static function for PUT
 * @param {string} path
 * @param {object} values
 * @param {object} options parseResponse, pathPrefix, headers
 * @returns
 */
export const put = (path, values, options = {}) =>
  request("PUT", path, { ...options, body: values })
