import { throttle } from "../lib/utils";

const Reveal = {
  mounted() {
    const parent = this.el.parentElement;

    const handleScroll = (e) => {
      const scrollPosition = e.target.scrollTop;

      if (scrollPosition > 70) {
        this.el.classList.add("reveal");
      } else {
        this.el.classList.remove("reveal");
      }
    };

    parent.addEventListener("scroll", throttle(handleScroll));
  }
};

export default Reveal;
