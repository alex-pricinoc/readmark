import { debounce } from "../lib/utils"

export default Open = {
  mounted() {
    const handleScroll = () => this.updateDOM()

    this.el.addEventListener("scroll", debounce(handleScroll))
    window.addEventListener("scroll", debounce(handleScroll))
  },
  updated() {
    this.updateDOM()
  },
  updateDOM() {
    if (this.el.scrollTop > 50 || window.scrollY > 50) {
      this.el.classList.add("open")
    } else {
      this.el.classList.remove("open")
    }
  }
}
