import { connect } from "./index.js"

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

test("connect is defined", () => {
  expect(connect).toBeDefined()
})

test("connect is a function", () => {
  expect(typeof connect).toBe("function")
})

describe("connect", () => {
  let elektron
  beforeEach(async () => {
    elektron = await connect(
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
})
