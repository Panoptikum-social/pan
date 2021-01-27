export const InitToast = {
  mounted() {
    init()
  }
}

const init = () => {
  const toastEl = document.querySelector('.toast')
  if (toastEl && toastEl.innerText !== '') {
    toastEl.classList.add("mr-4")

    setTimeout(() => {
      toastEl.classList.toggle("-mr-64", "mr-4")
    }, 3000);
  }
}

init()
