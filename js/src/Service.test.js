import Service from "./Service"
import { get } from "./Client"
import Token from "./Token"
import TestTokenData from "./TestTokenData"

jest.mock("./Client", () => {
  //Mock the default export

  return {
    __esModule: true,

    head: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
    }),
    del: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
    }),
    get: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ test: "test" }),
    }),
    post: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ test: "test" }),
    }),
    put: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ test: "test" }),
    }),
    patch: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ test: "test" }),
    }),
  }
})

describe("Service", () => {
  const session = {
    getAuth: jest
      .fn()
      .mockResolvedValue(["authToken", new Token(TestTokenData)]),
  }

  test("Service is a function", () => {
    expect(typeof Service).toEqual("function")
  })

  test("service by name", async () => {
    const volume = Service("volumev2", session)
    await volume.get("/volumes")

    expect(get).toHaveBeenLastCalledWith("/volumes", {
      headers: {
        "X-Auth-Token": "authToken",
      },
      host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
    })
  })

  describe("Service options", () => {
    test("pathPrefix", async () => {
      const volume = Service("volumev2", session, { pathPrefix: "v2" })
      await volume.get("/volumes")

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
        pathPrefix: "v2",
      })
    })
    test("parseResponse", async () => {
      const volume = Service("volumev2", session, { parseResponse: true })
      await volume.get("/volumes")

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
        parseResponse: true,
      })
    })

    test("headers", async () => {
      const volume = Service("volumev2", session, { headers: { test: "TEST" } })
      await volume.get("/volumes")

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
          test: "TEST",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
      })
    })
  })

  describe("Service request options", () => {
    test("headers", async () => {
      const volume = Service("volumev2", session)
      await volume.get("/volumes", { headers: { test: "TEST" } })

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
          test: "TEST",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
      })
    })

    test("parseResponse", async () => {
      const volume = Service("volumev2", session)
      await volume.get("/volumes", { parseResponse: true })

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
        parseResponse: true,
      })
    })

    test("pathPrefix", async () => {
      const volume = Service("volumev2", session)
      await volume.get("/volumes", { pathPrefix: "v2" })

      expect(get).toHaveBeenLastCalledWith("/volumes", {
        headers: {
          "X-Auth-Token": "authToken",
        },
        host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
        pathPrefix: "v2",
      })
    })
  })
})
