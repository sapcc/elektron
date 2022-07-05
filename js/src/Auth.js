/**
 * Implements the auth session
 * @param {string} endpoint an URL
 * @param {object} authConf an object which can contain
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
