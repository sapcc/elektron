import Client from "./Client"
import Auth from "./Auth"

function Elektron(endpoint, authConf) {
  if (!endpoint || typeof endpoint !== "string" || endpoint === "")
    throw new Error(
      "Missing parameter: endpoint. Please provide a valid identity endpoint."
    )
}
export default Elektron
