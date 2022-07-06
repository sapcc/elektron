import { connect } from "./index.js"

test("connect is defined", () => {
  expect(connect).toBeDefined()
})

test("connect is a function", () => {
  expect(typeof connect).toBe("function")
})

test("get client", () => {
  connect(
    "https://identity-3.qa-de-1.cloud.sap/v3",
    {
      userName: "D064310",

      userDomainName: "monsoon3",
      scopeProjectDomainName: "monsoon3",
      scopeProjectName: "cc-demo",
    },
    {
      headers: { "X-OpenStack-Nova-API-Version": "2.60" },
      parseResponse: true,
    }
  ).then((elektron) => {
    elektron
      .service("compute")
      .get("/servers")
      .then((data) => console.log("=====================", data))
  })
})
