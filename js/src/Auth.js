/**
 * Convert auth config to keystone authentication object
 * @param {object} authConf an object which can contain
 * possible properties:
 * AUTH
 * - token: a valid keystone auth token. If token is given, no further information is necessary
 * - userId: user ID
 * - userName: user name, only one of the two is necessary userId or userName
 * - userDomainId: domain id where the user is registered
 * - userDomainName: domain name where the user is registered, only one of the two is necessary userDomainId or userDomainName
 * - password: user password
 * SCOPE
 * - scopeProjectId: project ID. If this parameter is given no further scope information is neccessary (project scope)
 * - scopeProjectName: project name. In this case scopeProjectDomainID or scopeProjectDomainName are neccessary. (project scope)
 * - scopeProjectDomainId: project domain id (project scope)
 * - scopeProjectDomainName: project domain name (project scope)
 * - scopeDomainId: domain id (domain scope)
 * - scopeDomainName: domain name (domain scope)
 */
function Auth(authConf) {
  if (
    !authConf ||
    typeof authConf !== "object" ||
    Object.keys(authConf).length === 0
  )
    throw new Error(
      "Missing parameter: auth conf. Please provide auth configuration."
    )

  const auth = { identity: {}, scope: "unscoped" }

  // build identity object
  if (authConf.token) {
    auth.identity = { methods: ["token"], token: authConf.token }
  } else {
    // console.log("authConf:", authConf)
    if (
      !(
        (authConf.userName || authConf.userId) &&
        (authConf.userDomainId || authConf.userDomainName) &&
        authConf.password
      )
    ) {
      throw new Error(
        "missing user parameter. In case of password authentication you must specify userId or userName, password and userDomainName or userDomainId"
      )
    }
    auth.identity = {
      methods: ["password"],
      password: { user: { password: authConf.password } },
    }

    if (authConf.userName) auth.identity.password.user.name = authConf.userName
    else auth.identity.password.user.id = authConf.userId

    if (authConf.userDomainName)
      auth.identity.password.user.domain = {
        name: authConf.userDomainName,
      }
    else auth.identity.password.user.domain = { id: authConf.userDomainId }
  }

  // build auth scope
  if (authConf.scopeProjectId)
    auth.scope = { project: { id: authConf.scopeProjectId } }
  else if (authConf.scopeProjectName) {
    auth.scope = { project: { name: authConf.scopeProjectName } }
    if (!authConf.scopeProjectDomainId && !authConf.scopeProjectDomainName) {
      throw new Error(
        "missing scope parameter. If you specify scopeProjectName, you must also specify scopeProjectDomainName or scopeProjectDomainId"
      )
    }
    if (authConf.scopeProjectDomainName)
      auth.scope.project.domain = {
        name: authConf.scopeProjectDomainName,
      }
    else if (authConf.scopeProjectDomainId)
      auth.scope.project.domain = { id: authConf.scopeProjectDomainId }
  } else if (authConf.scopeDomainName)
    auth.scope.domain = { name: authConf.scopeDomainName }
  else if (authConf.scopeDomainId)
    auth.scope.domain = { id: authConf.scopeDomainId }
  else auth.scope = "unscoped"

  return { auth }
}

export default Auth
