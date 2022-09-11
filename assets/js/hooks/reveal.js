import { throttle } from "../lib/utils"

const Reveal = {
  mounted() {
    const handleScroll = () => this.updateDOM()

    this.el.addEventListener("scroll", throttle(handleScroll))
  },

  updated() {
    this.updateDOM()
  },

  updateDOM() {
    if (this.el.scrollTop > 70) {
      this.el.classList.add("reveal")
    } else {
      this.el.classList.remove("reveal")
    }
  }
}

export default Reveal
