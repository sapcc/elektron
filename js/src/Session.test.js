import Session from "./Session"
import Client from "./Client"

jest.mock("./Client", () => {
  //Mock the default export
  const TestTokenData = require("./TestTokenData")

  return {
    __esModule: true,
    default: {
      get: jest.fn().mockResolvedValue({
        headers: { get: () => "header" },
        json: jest.fn().mockResolvedValue({ token: TestTokenData }),
      }),
      post: jest.fn().mockResolvedValue({
        headers: { get: () => "header" },
        json: jest.fn().mockResolvedValue({ token: TestTokenData }),
      }),
    },
  }
})

test("Session is defined", () => {
  expect(Session).toBeDefined()
})

test("Session is a function", () => {
  expect(typeof Session).toBe("function")
})

describe("new Session instance", () => {
  test("throws an missing endpoint error", () => {
    expect(() => {
      new Session()
    }).toThrow(/missing parameter: endpoint/i)
  })
  test("throws an missing auth parameters error", () => {
    expect(() => {
      new Session("https://IDENTITY")
    }).toThrow(/missing parameter: auth conf/i)
  })

  describe("token validation", () => {
    let session
    beforeEach(() => {
      session = new Session("http://identity.com/v3", {
        token: "TEST_TOKEN",
      })
    })

    test("authentication", () => {
      session.authenticate()
      expect(Client.get).toHaveBeenLastCalledWith(
        "http://identity.com/v3/auth/tokens",
        {
          headers: {
            "X-Auth-Token": "TEST_TOKEN",
            "X-Subject-Token": "TEST_TOKEN",
          },
        }
      )
    })
  })

  describe("token authentication", () => {
    let session
    beforeEach(() => {
      session = new Session("http://identity.com/v3", {
        token: "TEST_TOKEN",
        scopeDomainName: "default",
      })
    })

    test("authentication", () => {
      session.authenticate()
      expect(Client.post).toHaveBeenLastCalledWith(
        "http://identity.com/v3/auth/tokens",
        {
          auth: {
            identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
            scope: { domain: { name: "default" } },
          },
        }
      )
    })
  })

  describe("password authentication", () => {
    let session
    beforeEach(() => {
      session = new Session("http://identity.com/v3", {
        userName: "TEST USER",
        password: "TEST",
        userDomainName: "default",
      })
    })

    test("authentication", () => {
      session.authenticate()
      expect(Client.post).toHaveBeenLastCalledWith(
        "http://identity.com/v3/auth/tokens",
        {
          auth: {
            identity: {
              methods: ["password"],
              password: {
                user: {
                  name: "TEST USER",
                  password: "TEST",
                  domain: { name: "default" },
                },
              },
            },
          },
        }
      )
    })
  })
})
