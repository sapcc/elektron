import Client from "./Client.js"
import fetch from "cross-fetch"

jest.mock("cross-fetch", () => {
  //Mock the default export
  return {
    __esModule: true,
    default: jest.fn().mockResolvedValue({
      status: 200,
      json: jest.fn().mockResolvedValue({}),
      text: jest.fn().mockResolvedValue("test"),
    }),
  }
})

describe("static methods", () => {
  test("responds to head", () => {
    expect(Client.head).toBeDefined()
  })
  test("responds to get", () => {
    expect(Client.get).toBeDefined()
  })
  test("responds to post", () => {
    expect(Client.post).toBeDefined()
  })
  test("responds to delete", () => {
    expect(Client.del).toBeDefined()
  })
  test("responds to put", () => {
    expect(Client.put).toBeDefined()
  })
  test("responds to patch", () => {
    expect(Client.patch).toBeDefined()
  })
})

describe("initializes a client", () => {
  let client
  beforeAll(() => {
    client = new Client({ url: "http://test.com" })
  })

  test("new client instance", () => {
    expect(client).toBeDefined()
  })

  test("responds to head", () => {
    expect(client.head).toBeDefined()
  })
  test("responds to get", () => {
    expect(client.get).toBeDefined()
  })
  test("responds to post", () => {
    expect(client.post).toBeDefined()
  })
  test("responds to delete", () => {
    expect(client.del).toBeDefined()
  })
  test("responds to put", () => {
    expect(client.put).toBeDefined()
  })
  test("responds to patch", () => {
    expect(client.patch).toBeDefined()
  })

  test("head", () => {
    client.head("/servers")
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "HEAD",
    })
  })

  test("get", () => {
    client.get("/servers")
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "GET",
    })
  })

  test("post", () => {
    client.post("/servers", { name: "test" })
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "POST",
      body: JSON.stringify({ name: "test" }),
    })
  })

  test("delete", () => {
    client.del("/servers/1")
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "DELETE",
    })
  })

  test("put", () => {
    client.put("/servers/1", { name: "test" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "PUT",
      body: JSON.stringify({ name: "test" }),
    })
  })

  test("patch", () => {
    client.patch("/servers/1", { name: "test" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "PATCH",
      body: JSON.stringify({ name: "test" }),
    })
  })
})

describe("pathPrefix", () => {
  test("should replace path prefix", () => {
    const client = new Client({ url: "http://test.com/v1" })
    client.head("/servers", { pathPrefix: "v2" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/v2/servers", {
      headers: { "Content-Type": "application/json" },
      method: "HEAD",
    })
  })
})
