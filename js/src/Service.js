import { head, get, post, put, patch, del } from "./Client"

const Service = (name, session, serviceOptions = {}) => {
  const clientParams = async (options) => {
    const [authToken, token] = await session.getAuth()

    if (!authToken || !token) throw new Error("No valid auth token available")

    const { interfaceName, region, headers, pathPrefix, parseResponse } = {
      ...serviceOptions,
      ...options,
    }

    const serviceURL = token.serviceURL(name, { interfaceName, region })

    if (!serviceURL)
      throw new Error(
        `Service ${name} (region: ${region}, interface: ${interfaceName}) not found.`
      )

    return {
      host: serviceURL,
      pathPrefix,
      parseResponse,
      headers: { ...headers, "X-Auth-Token": authToken },
    }
  }

  return {
    head: async (path, options = {}) =>
      clientParams(options).then((params) => head(path, params)),

    get: async (path, options = {}) =>
      clientParams(options).then((params) => get(path, params)),

    post: async (path, values, options) =>
      clientParams(options).then((params) =>
        post(path, { ...params, body: values })
      ),

    put: async (path, values, options = {}) =>
      clientParams(options).then((params) =>
        put(path, { ...params, body: values })
      ),

    patch: async (path, values, options = {}) =>
      clientParams(options).then((params) =>
        patch(path, { ...params, body: values })
      ),

    del: async (path, options = {}) =>
      clientParams(options).then((params) => del(path, params)),
  }
}

export default Service
