export function throttle(func, limit = 75) {
  let inThrottle

  return function() {
    let context = this,
      args = arguments

    if (!inThrottle) {
      func.apply(context, args)
      inThrottle = true

      setTimeout(() => {
        func.apply(context, args)
        inThrottle = false
      }, limit)
    }
  }
}

export function findChildOrThrow(element, selector) {
  const child = element.querySelector(selector)

  if (!child) {
    throw new Error(`expected a child matching ${selector}, but none was found`)
  }

  return child
}
