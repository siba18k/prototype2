document.addEventListener("DOMContentLoaded", () => {
  // Declare bootstrap
  const bootstrap = window.bootstrap

  // Declare loadUserData
  const loadUserData = window.loadUserData

  // Initialize auth modals
  const signinModal = new bootstrap.Modal(document.getElementById("signinModal"))
  const signupModal = new bootstrap.Modal(document.getElementById("signupModal"))

  // Signup form handler
  document.getElementById("signupForm")?.addEventListener("submit", async (e) => {
    e.preventDefault()
    const form = e.target
    const submitBtn = form.querySelector('button[type="submit"]')

    submitBtn.disabled = true

    try {
      const response = await fetch("/api/auth/register.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: form.signupEmail.value,
          password: form.signupPassword.value,
          full_name: form.signupFullName?.value,
        }),
      })

      const data = await response.json()

      if (data.success) {
        showToast("Registration successful! Please sign in", "success")
        signupModal.hide()
        form.reset()
        signinModal.show()
      } else {
        showToast(data.message || "Registration failed", "error")
      }
    } catch (error) {
      showToast("Network error. Please try again.", "error")
    } finally {
      submitBtn.disabled = false
    }
  })

  // Signin form handler
  document.getElementById("signinForm")?.addEventListener("submit", async (e) => {
    e.preventDefault()
    const form = e.target
    const submitBtn = form.querySelector('button[type="submit"]')

    submitBtn.disabled = true

    try {
      const response = await fetch("/api/auth/login.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: form.signinEmail.value,
          password: form.signinPassword.value,
        }),
        credentials: "include",
      })

      const data = await response.json()

      if (data.success) {
        showToast("Login successful!", "success")
        signinModal.hide()
        form.reset()
        updateAuthUI(true)
        if (typeof loadUserData === "function") loadUserData()

        // Redirect if there's a stored redirect URL
        if (sessionStorage.getItem("redirectUrl")) {
          window.location.href = sessionStorage.getItem("redirectUrl")
          sessionStorage.removeItem("redirectUrl")
        }
      } else {
        showToast(data.message || "Login failed", "error")
      }
    } catch (error) {
      showToast("Network error. Please try again.", "error")
    } finally {
      submitBtn.disabled = false
    }
  })

  // Logout handler
  document.getElementById("logoutBtn")?.addEventListener("click", async () => {
    try {
      const response = await fetch("/api/auth/logout.php", {
        method: "POST",
        credentials: "include",
      })

      const data = await response.json()

      if (data.success) {
        showToast("Logged out successfully", "success")
        updateAuthUI(false)
        if (window.location.pathname !== "/index.html") {
          window.location.href = "index.html"
        }
      }
    } catch (error) {
      showToast("Logout failed", "error")
    }
  })

  // Update UI based on auth state
  function updateAuthUI(isLoggedIn) {
    const authButtons = document.querySelector(".auth-buttons")
    if (!authButtons) return

    authButtons.innerHTML = isLoggedIn
      ? `
            <a href="/dashboard.html" class="btn btn-outline-primary me-2">Dashboard</a>
            <button id="logoutBtn" class="btn btn-danger">Logout</button>
        `
      : `
            <button class="btn btn-outline-primary me-2" data-bs-toggle="modal" data-bs-target="#signinModal">Sign in</button>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#signupModal">Sign up</button>
        `

    // Add event listener to new logout button
    document.getElementById("logoutBtn")?.addEventListener("click", async () => {
      try {
        const response = await fetch("/api/auth/logout.php", {
          method: "POST",
          credentials: "include",
        })

        const data = await response.json()

        if (data.success) {
          showToast("Logged out successfully", "success")
          updateAuthUI(false)
          if (window.location.pathname !== "/index.html") {
            window.location.href = "index.html"
          }
        }
      } catch (error) {
        showToast("Logout failed", "error")
      }
    })
  }

  // Check auth status on page load
  async function checkAuthStatus() {
    try {
      const response = await fetch("/api/auth/me.php", {
        credentials: "include",
      })

      if (response.ok) {
        const data = await response.json()
        updateAuthUI(data.authenticated)
        if (data.authenticated && typeof loadUserData === "function") {
          loadUserData()
        }
      }
    } catch (error) {
      console.error("Auth check failed:", error)
    }
  }

  // Toast notification function
  function showToast(message, type = "info") {
    const toast = document.createElement("div")
    toast.className = `toast show align-items-center text-white bg-${type}`
    toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `
    document.body.appendChild(toast)
    setTimeout(() => toast.remove(), 5000)
  }

  // Initialize auth check
  checkAuthStatus()
})
