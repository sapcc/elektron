import Auth from "./Auth"
import Client from "./Client"
import Token from "./Token"

/**
 * Implements the auth session
 * @param {string} endpoint an URL
 * @param {object} authConf an object which can contain
 */
function Session(endpoint, authConf, options = {}) {
  if (!endpoint || typeof endpoint !== "string" || endpoint === "")
    throw new Error(
      "Missing parameter: endpoint. Please provide a valid identity endpoint."
    )
  if (
    !authConf ||
    typeof authConf !== "object" ||
    Object.keys(authConf).length === 0
  )
    throw new Error(
      "Missing parameter: auth conf. Please provide auth configuration."
    )

  this.options = options
  this.auth = Auth(authConf)
  this.endpoint = new URL("/v3/auth/tokens", endpoint).toString()
}

Session.prototype.authenticate = async function () {
  if (this.authToken && this.token && this.expiresAt > Date.now()) return this
  return Client.post(this.endpoint, this.auth).then(async (response) => {
    this.authToken = response.headers.get("x-subject-token")
    const data = await response.json()
    this.token = new Token(data.token)
    return this
  })
}

Session.prototype.logout = async function () {
  return Client.delete(this.endpoint, {
    headers: {
      "X-Auth-Token": this.authToken,
      "X-Subject-Token": this.authToken,
    },
  })
}

Session.prototype.getAuthToken = async function () {
  await this.authenticate()
  return this.authToken
}

Session.prototype.getToken = async function () {
  await this.authenticate()
  return this.token
}

export default Session
