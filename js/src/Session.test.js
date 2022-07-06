import Session from "./Session.js"

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

  // test("authentication", (done) => {
  //   const session = new Session("https://identity-3.qa-de-1.cloud.sap/v3", {
  //     userName: "D064310",
  //     userDomainName: "monsoon3",
  //     scopeProjectDomainName: "monsoon3",
  //     scopeProjectName: "cc-demo",
  //   })

  //   session.getAuthToken().then(() => {
  //     console.log("----------------", session.token)
  //     console.log(session.token.serviceUrl("compute"))
  //   })
  // })

  //   describe("auth configuration", () => {
  //     test("token authentication", () => {
  //       const auth = new Auth("https://test", {
  //         token: "TEST_TOKEN",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: { methods: ["token"], token: "TEST_TOKEN" },
  //         scope: "unscoped",
  //       })
  //     })
  //     test("token authentication with scope", () => {
  //       const auth = new Auth("https://test", {
  //         token: "TEST_TOKEN",
  //         scopeProjectId: "123456",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: { methods: ["token"], token: "TEST_TOKEN" },
  //         scope: { project: { id: "123456" } },
  //       })
  //     })
  //     test("token authentication with project and domain scope", () => {
  //       const auth = new Auth("https://test", {
  //         token: "TEST_TOKEN",
  //         scopeProjectName: "project",
  //         scopeProjectDomainName: "domain",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: { methods: ["token"], token: "TEST_TOKEN" },
  //         scope: { project: { name: "project", domain: { name: "domain" } } },
  //       })
  //     })
  //     test("token authentication with project and domain scope", () => {
  //       const auth = new Auth("https://test", {
  //         token: "TEST_TOKEN",
  //         scopeProjectName: "project",
  //         scopeProjectDomainId: "test",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: { methods: ["token"], token: "TEST_TOKEN" },
  //         scope: { project: { name: "project", domain: { id: "test" } } },
  //       })
  //     })
  //     test("token authentication with project id scope", () => {
  //       const auth = new Auth("https://test", {
  //         token: "TEST_TOKEN",
  //         scopeProjectId: "12345",
  //         scopeProjectDomainId: "test",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: { methods: ["token"], token: "TEST_TOKEN" },
  //         scope: { project: { id: "12345" } },
  //       })
  //     })
  //     test("password authentication with project id scope", () => {
  //       const auth = new Auth("https://test", {
  //         userName: "user",
  //         userDomainId: "12345",
  //         password: "Password",
  //         scopeProjectName: "test",
  //         scopeProjectDomainName: "test",
  //       })
  //       expect(auth.auth).toEqual({
  //         identity: {
  //           methods: ["password"],
  //           password: {
  //             user: {
  //               name: "user",
  //               password: "Password",
  //               domain: { id: "12345" },
  //             },
  //           },
  //         },
  //         scope: { project: { name: "test", domain: { name: "test" } } },
  //       })
  //     })
  //   })
})
