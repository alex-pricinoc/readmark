export function debounce(fn) {
  let raf;

  return (...args) => {
    if (raf) {
      return;
    }

    raf = requestAnimationFrame(() => {
      fn(...args);
      raf = undefined;
    });
  };
}

export function findChildOrThrow(element, selector) {
  const child = element.querySelector(selector);

  if (!child) {
    throw new Error(`expected a child matching ${selector}, but none was found`);
  }

  return child;
}

export function smoothScrollTo(y, el = window, duration = 500, offset = 0) {
  const startY = el.scrollTop || el.scrollY;
  const difference = y - startY;
  const startTime = performance.now();

  const step = () => {
    const progress = (performance.now() - startTime) / duration;
    const amount = EasingFunctions.easeOutQuart(progress);
    el.scrollTo({ top: startY + amount * difference - offset });
    if (progress < 0.99) {
      requestAnimationFrame(step);
    }
  };
  step();
}

// https://gist.github.com/gre/1650294
const EasingFunctions = {
  // no easing, no acceleration
  linear: t => t,
  // accelerating from zero velocity
  easeInQuad: t => t * t,
  // decelerating to zero velocity
  easeOutQuad: t => t * (2 - t),
  // acceleration until halfway, then deceleration
  easeInOutQuad: t => t < .5 ? 2 * t * t : -1 + (4 - 2 * t) * t,
  // accelerating from zero velocity
  easeInCubic: t => t * t * t,
  // decelerating to zero velocity
  easeOutCubic: t => (--t) * t * t + 1,
  // acceleration until halfway, then deceleration
  easeInOutCubic: t => t < .5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1,
  // accelerating from zero velocity
  easeInQuart: t => t * t * t * t,
  // decelerating to zero velocity
  easeOutQuart: t => 1 - (--t) * t * t * t,
  // acceleration until halfway, then deceleration
  easeInOutQuart: t => t < .5 ? 8 * t * t * t * t : 1 - 8 * (--t) * t * t * t,
  // accelerating from zero velocity
  easeInQuint: t => t * t * t * t * t,
  // decelerating to zero velocity
  easeOutQuint: t => 1 + (--t) * t * t * t * t,
  // acceleration until halfway, then deceleration
  easeInOutQuint: t => t < .5 ? 16 * t * t * t * t * t : 1 + 16 * (--t) * t * t * t * t,
};
