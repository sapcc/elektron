import Token from "./Token"
import TestTokenData from "./TestTokenData"

describe("Token", () => {
  test("is a function", () => {
    expect(typeof Token).toEqual("function")
  })

  describe("instance of Token", () => {
    let token
    beforeAll(() => {
      token = new Token(TestTokenData)
    })

    test("expiresAt", () => {
      expect(token.expiresAt).toEqual(Date.parse("2022-07-06T16:56:59.000000Z"))
    })

    test("roleNames", () => {
      expect(token.roleNames).toEqual([
        "resource_viewer",
        "email_admin",
        "audit_viewer",
      ])
    })

    test("availableRegions", () => {
      expect(token.availableRegions).toEqual(["qa-de-1", "staging"])
    })

    test("isExpired", () => {
      expect(token.isExpired()).toEqual(true)
    })

    test("hasService -> false", () => {
      expect(token.hasService("volume")).toEqual(false)
    })

    test("hasService -> true", () => {
      expect(token.hasService("volumev2")).toEqual(true)
    })

    test("hasRole -> false", () => {
      expect(token.hasRole("admin")).toEqual(false)
    })

    test("hasRole -> true", () => {
      expect(token.hasRole("email_admin")).toEqual(true)
    })

    test("serviceURL", () => {
      expect(token.serviceURL("volumev2")).toEqual(
        "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132"
      )
    })

    test("serviceURL for internal endpoint", () => {
      expect(
        token.serviceURL("volumev2", { interfaceName: "internal" })
      ).toEqual(
        "http://cinder-api.monsoon3.svc.kubernetes.qa-de-1.cloud.sap:8776/v2/e9141fb24eee4b3e9f25ae69cda31132"
      )
    })

    test("serviceURL for internal endpoint", () => {
      expect(token.serviceURL("volumev2", { interfaceName: "admin" })).toEqual(
        "http://cinder-api.monsoon3.svc.kubernetes.qa-de-1.cloud.sap:8776/v2/e9141fb24eee4b3e9f25ae69cda31132"
      )
    })

    test("serviceURL for region staging", () => {
      expect(token.serviceURL("hermes", { region: "staging" })).toEqual(
        "https://hermes.staging.cloud.sap/v1"
      )
    })

    test("value", () => {
      expect(token.value("user.domain.id")).toEqual(
        "2bac466eed364d8a92e477459e908736"
      )
    })
  })
})
