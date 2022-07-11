import * as Client from "./Client"

const Service = (name, session, serviceOptions = {}) => {
  const clientParams = async (options) => {
    const [authToken, token] = await session.getAuth()

    if (!authToken || !token) throw new Error("No valid auth token available")

    let { interfaceName, region, headers, pathPrefix, parseResponse, debug } = {
      ...serviceOptions,
      ...options,
    }

    interfaceName = interfaceName || "public"

    const serviceURL = token.serviceURL(name, {
      interfaceName,
      region,
    })

    if (!serviceURL)
      throw new Error(
        `Service ${name} (region: ${region}, interface: ${interfaceName}) not found.`
      )

    return {
      host: serviceURL,
      pathPrefix,
      parseResponse,
      headers: { ...headers, "X-Auth-Token": authToken },
      debug,
    }
  }

  return {
    head: async (path, options = {}) =>
      clientParams(options).then((params) => Client.head(path, params)),

    get: async (path, options = {}) =>
      clientParams(options).then((params) => Client.get(path, params)),
    post: async (path, values, options) =>
      clientParams(options).then((params) =>
        Client.post(path, { ...params, body: values })
      ),

    put: async (path, values, options = {}) =>
      clientParams(options).then((params) =>
        Client.put(path, { ...params, body: values })
      ),

    patch: async (path, values, options = {}) =>
      clientParams(options).then((params) =>
        Client.patch(path, { ...params, body: values })
      ),

    del: async (path, options = {}) =>
      clientParams(options).then((params) => Client.del(path, params)),
  }
}

export default Service
