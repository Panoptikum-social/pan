// "N characters left" below a text input: the input names its counter with
// data-remaining-counter="<element id>" and has a maxlength. Listening on the
// document keeps this working across LiveView re-renders and needs no inline
// script (Content-Security-Policy).
document.addEventListener("input", (event) => {
  const counterId = event.target.dataset && event.target.dataset.remainingCounter;
  const counter = counterId && document.getElementById(counterId);

  if (counter) {
    counter.textContent = event.target.maxLength - event.target.value.length;
  }
});
