import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "option"]

  connect() {
    this.root = document.documentElement
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.sync = this.sync.bind(this)
    this.media.addEventListener("change", this.sync)
    this.sync()
  }

  disconnect() {
    this.media.removeEventListener("change", this.sync)
  }

  change(event) {
    const theme = event.currentTarget.dataset.themeName
    if (!this.root.dataset.themes.split(" ").includes(theme)) return

    this.root.dataset.themePreference = theme
    this.sync()

    try {
      localStorage.setItem("theme", theme)
    } catch (_) {}
    this.close()
  }

  close() {
    if (!this.element.open) return

    this.element.open = false
    this.triggerTarget.focus()
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.element.open = false
  }

  sync() {
    const theme = this.root.dataset.themePreference || (this.media.matches ? "dark" : "light")
    this.root.dataset.theme = theme
    this.triggerTarget.title = `Theme: ${theme}`
    this.triggerTarget.setAttribute("aria-label", `Choose theme. Current: ${theme}`)
    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-pressed", option.dataset.themeName === theme)
    })
  }
}
