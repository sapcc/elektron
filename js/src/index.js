import Service from "./Service"
import Session from "./Session"

const DEFAULT_OPTIONS = {
  headers: { "Content-Type": "application/json" },
  parseResponse: true,
  debug: false,
}

const Elektron = (identityURL, authConf, options = {}) => {
  const session = new Session(identityURL, authConf)

  return {
    service: (name, serviceOptions = {}) =>
      Service(name, session, {
        ...DEFAULT_OPTIONS,
        ...options,
        ...serviceOptions,
      }),
    logout: session.logout,
    token: async () => session.getAuth().then(([_authToken, token]) => token),
    authToken: async () =>
      session.getAuth().then(([authToken, _token]) => authToken),
  }
}

export default Elektron
