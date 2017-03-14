int fib(n1, n2, i, max) {
  if (i == max) return n1;
  return fib(n2, n1 + n2, i + 1, max);
}

int fib_to(max) {
  return fib(0, 1, 0, max);
}
