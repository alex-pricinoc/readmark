export function throttle(func, limit = 100) {
  let inThrottle;

  return function () {
    let context = this,
      args = arguments;

    if (!inThrottle) {
      func.apply(context, args);
      inThrottle = true;

      setTimeout(() => {
        func.apply(context, args);
        inThrottle = false;
      }, limit);
    }
  };
}
