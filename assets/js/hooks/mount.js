const Mount = {
  mounted() {
    liveSocket.execJS(this.el, this.el.getAttribute("phx-mount"))
  }
}

export default Mount
