import Service from "./Service"
import Session from "./Session"

const Elektron = (identityURL, authConf, options = {}) => {
  const session = new Session(identityURL, authConf)

  return {
    service: (name, serviceOptions = {}) =>
      Service(name, session, { ...options, ...serviceOptions }),
    logout: session.logout,
    token: async () => session.getAuth().then(([authToken, token]) => token),
    authToken: async () =>
      session.getAuth().then(([authToken, token]) => authToken),
  }
}

export default Elektron
