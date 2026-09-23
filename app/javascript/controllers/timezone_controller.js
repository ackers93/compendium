import { Controller } from "@hotwired/stimulus"

const COOKIE_NAME = "time_zone"
const MAX_AGE_SECONDS = 60 * 60 * 24 * 365

export default class extends Controller {
  connect() {
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!timeZone) return

    if (this.#readCookie(COOKIE_NAME) === timeZone) return

    this.#writeCookie(COOKIE_NAME, timeZone)

    // Reload once so the server can resolve Date.current in the browser zone.
    if (this.#readCookie(COOKIE_NAME) === timeZone) {
      window.location.reload()
    }
  }

  #readCookie(name) {
    const prefix = `${name}=`
    const match = document.cookie
      .split("; ")
      .find((entry) => entry.startsWith(prefix))

    if (!match) return null

    return decodeURIComponent(match.slice(prefix.length))
  }

  #writeCookie(name, value) {
    const secure = window.location.protocol === "https:" ? "; Secure" : ""
    document.cookie =
      `${name}=${encodeURIComponent(value)}; path=/; max-age=${MAX_AGE_SECONDS}; SameSite=Lax${secure}`
  }
}
