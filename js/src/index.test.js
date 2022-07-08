import Elektron from "./index.js"

jest.mock("./Client", () => {
  //Mock the default export
  const TestTokenData = require("./TestTokenData")

  return {
    __esModule: true,

    get: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ token: TestTokenData }),
    }),
    post: jest.fn().mockResolvedValue({
      headers: { get: () => "header" },
      json: jest.fn().mockResolvedValue({ token: TestTokenData }),
    }),
  }
})

test("Elektron is defined", () => {
  expect(Elektron).toBeDefined()
})

test("Elektron is a function", () => {
  expect(typeof Elektron).toBe("function")
})

describe("Elektron", () => {
  let elektron
  beforeEach(async () => {
    elektron = Elektron(
      "https://identity-3.qa-de-1.cloud.sap/v3",
      {
        token: "test",
      },
      {
        headers: { "X-OpenStack-Nova-API-Version": "2.60" },
        parseResponse: true,
      }
    )
  })

  test("responds to service", () => {
    expect(typeof elektron.service).toEqual("function")
  })

  test("responds to volumev2 service ", () => {
    expect(typeof elektron.service("volumev2")).toEqual("object")
  })

  test("service responds to get", () => {
    expect(typeof elektron.service("volumev2").get).toEqual("function")
  })
})
