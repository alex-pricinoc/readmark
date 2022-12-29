export default InfiniteScroll = {
  loadMore(entries) {
    const [target] = entries
    if (target.isIntersecting) {
      this.pushEvent("load-more", {})
    }
  },
  mounted() {
    const scrollArea = document.querySelector("[data-scroll-area]")

    let options = {
      root: scrollArea,
      rootMargin: "400px",
      threshold: 0.1
    }

    this.observer = new IntersectionObserver(entries => this.loadMore(entries), options)
    this.observer.observe(this.el)
  },
  destroyed() {
    this.observer.unobserve(this.el)
  }
}
