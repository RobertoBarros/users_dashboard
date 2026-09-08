(() => {
  const root = document.documentElement
  let preference

  try {
    preference = localStorage.getItem("theme")
  } catch (_) {}

  if (root.dataset.themes.split(" ").includes(preference)) {
    root.dataset.themePreference = preference
  }

  root.dataset.theme = root.dataset.themePreference ||
    (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
})()
