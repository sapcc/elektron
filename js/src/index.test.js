import Elektron from "./index.js"
import { get } from "./Client"

jest.mock("./Client", () => {
  //Mock the default export
  const TestTokenData = require("./TestTokenData")

  return {
    __esModule: true,

    get: jest.fn().mockResolvedValue({
      headers: { get: () => "TEST_TOKEN" },
      json: jest.fn().mockResolvedValue({ token: TestTokenData.default }),
    }),
    post: jest.fn().mockResolvedValue({
      headers: { get: () => "TEST_TOKEN" },
      json: jest.fn().mockResolvedValue({ token: TestTokenData.default }),
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
    elektron = Elektron("https://identity-3.qa-de-1.cloud.sap/v3", {
      token: "test",
    })
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

  test("Default Options", async () => {
    await elektron.service("volumev2").get("/volumes", { debug: true })
    expect(get).toHaveBeenLastCalledWith("/volumes", {
      headers: {
        "Content-Type": "application/json",
        "X-Auth-Token": "TEST_TOKEN",
      },
      parseResponse: true,
      host: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
      debug: true,
    })
  })
})
