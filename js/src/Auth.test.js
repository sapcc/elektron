import Auth from "./Auth.js"

test("Auth is defined", () => {
  expect(Auth).toBeDefined()
})

test("Auth is a function", () => {
  expect(typeof Auth).toBe("function")
})

describe("Auth object", () => {
  test("throws an missing auth parameters error", () => {
    expect(() => {
      Auth()
    }).toThrow(/missing parameter: auth conf/i)
  })

  test("token authentication", () => {
    const auth = Auth({
      token: "TEST_TOKEN",
      unscoped: true,
    })
    expect(auth).toEqual({
      auth: {
        identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
        scope: "unscoped",
      },
    })
  })

  test("token authentication with scope", () => {
    const auth = Auth({
      token: "TEST_TOKEN",
      scopeProjectId: "123456",
    })
    expect(auth).toEqual({
      auth: {
        identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
        scope: { project: { id: "123456" } },
      },
    })
  })

  test("token authentication with project and domain scope", () => {
    const auth = Auth({
      token: "TEST_TOKEN",
      scopeProjectName: "project",
      scopeProjectDomainName: "domain",
    })
    expect(auth).toEqual({
      auth: {
        identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
        scope: { project: { name: "project", domain: { name: "domain" } } },
      },
    })
  })

  test("token authentication with project and domain scope", () => {
    const auth = Auth({
      token: "TEST_TOKEN",
      scopeProjectName: "project",
      scopeProjectDomainId: "test",
    })
    expect(auth).toEqual({
      auth: {
        identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
        scope: { project: { name: "project", domain: { id: "test" } } },
      },
    })
  })

  test("token authentication with project id scope", () => {
    const auth = Auth({
      token: "TEST_TOKEN",
      scopeProjectId: "12345",
      scopeProjectDomainId: "test",
    })
    expect(auth).toEqual({
      auth: {
        identity: { methods: ["token"], token: { id: "TEST_TOKEN" } },
        scope: { project: { id: "12345" } },
      },
    })
  })

  test("password authentication with project id scope", () => {
    const auth = Auth({
      userName: "user",
      userDomainId: "12345",
      password: "Password",
      scopeProjectName: "test",
      scopeProjectDomainName: "test",
    })
    expect(auth).toEqual({
      auth: {
        identity: {
          methods: ["password"],
          password: {
            user: {
              name: "user",
              password: "Password",
              domain: { id: "12345" },
            },
          },
        },
        scope: { project: { name: "test", domain: { name: "test" } } },
      },
    })
  })
})
