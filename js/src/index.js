import Client from "./Client"
import Session from "./Session"

async function connect(url, authConf, options = {}) {
  const session = new Session(url, authConf)
  await session.authenticate()
  const clients = {}

  return {
    // serviceOptions = {interfaceName,region, headers, parseResponse, pathPrefix}
    service: (name, serviceOptions = {}) => {
      const { interfaceName, region } = serviceOptions
      const serviceUrl = session.token.serviceUrl(name, {
        region,
        interfaceName,
      })
      if (!serviceUrl) return null

      clients[name] =
        clients[name] ||
        new Client({
          url: serviceUrl,
          headers: {
            "X-Auth-Token": session.authToken,
            ...options.headers,
            ...serviceOptions.headers,
          },
          parseResponse:
            options.parseResponse === true ||
            serviceOptions.parseResponse === true,
          pathPrefix: options.pathPrefix || serviceOptions.pathPrefix || false,
        })

      return clients[name]
    },
    logout: session.logout,
  }
}
export { connect }
