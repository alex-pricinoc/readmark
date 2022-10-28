const Flash = {
  mounted() {
    let hide = () => liveSocket.execJS(this.el, this.el.getAttribute("phx-click"))
    this.timer = setTimeout(() => hide(), 5000)
    this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer))
    this.el.addEventListener("mouseover", () => {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => hide(), 5000)
    })
  },
  destroyed() {
    clearTimeout(this.timer)
  }
}

export default Flash
