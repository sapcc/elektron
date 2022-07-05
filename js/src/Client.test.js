import Client from "./Client.js"

describe("initializes a client", () => {
  let client
  beforeAll(() => {
    client = new Client()
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
})
