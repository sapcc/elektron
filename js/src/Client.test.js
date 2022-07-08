import * as Client from "./Client.js"
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

describe("Client methods", () => {
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

  test("head", () => {
    Client.head("/servers", { host: "http://test.com" })
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "HEAD",
    })
  })

  test("get", () => {
    Client.get("/servers", { host: "http://test.com" })
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "GET",
    })
  })

  test("post", () => {
    Client.post("/servers", { name: "test" }, { host: "http://test.com" })
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers", {
      headers: { "Content-Type": "application/json" },
      method: "POST",
      body: JSON.stringify({ name: "test" }),
    })
  })

  test("delete", () => {
    Client.del("/servers/1", { host: "http://test.com" })
    expect(fetch).toHaveBeenCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "DELETE",
    })
  })

  test("put", () => {
    Client.put("/servers/1", { name: "test" }, { host: "http://test.com" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "PUT",
      body: JSON.stringify({ name: "test" }),
    })
  })

  test("patch", () => {
    Client.patch("/servers/1", { name: "test" }, { host: "http://test.com" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/servers/1", {
      headers: { "Content-Type": "application/json" },
      method: "PATCH",
      body: JSON.stringify({ name: "test" }),
    })
  })
})

describe("pathPrefix", () => {
  test("should replace path prefix", () => {
    Client.head("/servers", { pathPrefix: "v2", host: "http://test.com/v1" })
    expect(fetch).toHaveBeenLastCalledWith("http://test.com/v2/servers", {
      headers: { "Content-Type": "application/json" },
      method: "HEAD",
    })
  })
})
