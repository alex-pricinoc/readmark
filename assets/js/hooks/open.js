import { throttle } from "../lib/utils"

const Open = {
  mounted() {
    const handleScroll = () => this.updateDOM()

    this.el.addEventListener("scroll", throttle(handleScroll))
  },

  updated() {
    this.updateDOM()
  },

  updateDOM() {
    if (this.el.scrollTop > 70) {
      this.el.classList.add("open")
    } else {
      this.el.classList.remove("open")
    }
  }
}

export default Open
