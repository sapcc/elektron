import Elektron from "./index.js"

test("Elektron is defined", () => {
  expect(Elektron).toBeDefined()
})

test("Elektron is a function", () => {
  expect(typeof Elektron).toBe("function")
})
