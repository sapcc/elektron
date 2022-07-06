import Client from "./Client"
import Session from "./Session"

async function connect(url, authConf, options = {}) {
  const session = new Session(url, authConf)
  await session.authenticate()
  const clients = {}

  return {
    service: (name, serviceOptions = {}) => {
      const serviceUrl = session.token.serviceUrl(name)
      if (!serviceUrl)
        throw new Error("Service not found. Could not find service " + name)

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
