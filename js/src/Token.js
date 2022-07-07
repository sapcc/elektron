function Token(tokenData) {
  this.tokenData = tokenData
  this.expiresAt = Date.parse(tokenData.expires_at)
  this.catalog = tokenData.catalog || tokenData.serviceCatalog || []
  this.roles = tokenData.roles || tokenData.user?.roles || []
  this.roleNames = (this.roles || []).map((role) =>
    typeof role === "string" ? role : role.name
  )

  this.availableRegions = this.tokenData.regions || []
  for (let service of this.catalog) {
    if (service.type === "identity") continue
    const endpoints = service.endpoints || []
    for (let endpoint of endpoints) {
      this.availableRegions.push(endpoint.region)
    }
  }
  this.availableRegions = this.availableRegions.filter(
    (value, index, self) => self.indexOf(value) === index
  )
}

Token.prototype.isExpired = function () {
  return this.expiresAt <= Date.now()
}

Token.prototype.hasService = function (name) {
  return !!this.catalog.find(
    (service) => service.type === name || service.name === name
  )
}
Token.prototype.hasRole = function (name) {
  return this.roleNames.indexOf(name) >= 0
}

Token.prototype.serviceUrl = function (type, options = {}) {
  const region =
    options.region ||
    (this.availableRegions.length > 0 && this.availableRegions[0])
  const interfaceName = options.interfaceName || "public"

  const service = this.catalog.find((s) => s.type === type || s.name === type)

  if (!service) return null

  const endpoint = service.endpoints.find(
    (e) => e.region_id === region && e.interface === interfaceName
  )

  if (!endpoint) return null

  return endpoint.url
}

Token.prototype.value = function (key) {
  const keys = key.split(".")
  let currentKey = keys.shift()
  let value = this.tokenData[currentKey]

  while (keys.length > 0) {
    currentKey = keys.shift()
    value = value && value[currentKey]
  }
  return value
}

export default Token
