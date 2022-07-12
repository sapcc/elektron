import Auth from "./Auth"
import { get, post } from "./Client"
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

  let request
  // if token id is given and scope not then validate token to get the catalog
  if (this.auth.auth.identity.token?.id && !this.auth.auth.scope) {
    request = get(this.endpoint, {
      headers: {
        "X-Auth-Token": this.auth.auth.identity.token.id,
        "X-Subject-Token": this.auth.auth.identity.token.id,
      },
      parseResponse: false,
    })
  } else {
    //else make authentication
    request = post(this.endpoint, this.auth, { parseResponse: false })
  }

  return request.then(async (response) => {
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

/**
 *
 * @returns array of authToken and tokenContext
 */
Session.prototype.getAuth = async function () {
  await this.authenticate()
  return [this.authToken, this.token]
}

export default Session
