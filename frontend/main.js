const API_BASE_URL = "http://127.0.0.1:5000";

function getStoredUser() {
    try {
        return JSON.parse(sessionStorage.getItem("iwes_user") || "null");
    } catch (error) {
        sessionStorage.removeItem("iwes_user");
        return null;
    }
}

function setStoredUser(user) {
    sessionStorage.setItem("iwes_user", JSON.stringify(user));
    sessionStorage.setItem("user_id", String(user.user_id));
}

function clearStoredUser() {
    sessionStorage.removeItem("iwes_user");
    sessionStorage.removeItem("user_id");
}

function setActiveNav() {
    const path = window.location.pathname.replace(/\/+$/, "");
    const rawPage = path.split("/").pop() || "index";
    const normalizedPage = rawPage.includes(".") ? rawPage : `${rawPage}.html`;
    document.querySelectorAll(".nav-link").forEach((link) => {
        link.classList.remove("active");
        link.removeAttribute("aria-current");
        const href = link.getAttribute("href");
        if (!href) {
            return;
        }
        const normalizedHref = href.includes(".") ? href : `${href}.html`;
        if (normalizedHref === normalizedPage) {
            link.classList.add("active");
            link.setAttribute("aria-current", "page");
        }
    });
}

function initResponsiveNav() {
    const mobileBreakpoint = 900;
    document.querySelectorAll(".navbar").forEach((navbar, index) => {
        if (!navbar || navbar.dataset.responsiveInit === "true") {
            return;
        }

        const navInner = navbar.querySelector(".nav-inner");
        const navLinks = navbar.querySelector(".nav-links");
        const navActions = navbar.querySelector(".nav-actions");
        if (!navInner || (!navLinks && !navActions)) {
            return;
        }

        const toggle = document.createElement("button");
        toggle.type = "button";
        toggle.className = "nav-toggle";
        toggle.setAttribute("aria-expanded", "false");
        toggle.setAttribute("aria-label", "Toggle navigation menu");

        const controls = [];
        if (navLinks) {
            navLinks.id ||= `nav-links-${index + 1}`;
            controls.push(navLinks.id);
        }
        if (navActions) {
            navActions.id ||= `nav-actions-${index + 1}`;
            controls.push(navActions.id);
        }
        if (controls.length) {
            toggle.setAttribute("aria-controls", controls.join(" "));
        }

        toggle.innerHTML = `
            <span class="nav-toggle-line" aria-hidden="true"></span>
            <span class="nav-toggle-line" aria-hidden="true"></span>
            <span class="nav-toggle-line" aria-hidden="true"></span>
        `;
        navInner.appendChild(toggle);

        const closeMenu = () => {
            navbar.classList.remove("menu-open");
            toggle.setAttribute("aria-expanded", "false");
        };

        toggle.addEventListener("click", () => {
            const nextState = !navbar.classList.contains("menu-open");
            navbar.classList.toggle("menu-open", nextState);
            toggle.setAttribute("aria-expanded", String(nextState));
        });

        navbar.querySelectorAll(".nav-link").forEach((link) => {
            link.addEventListener("click", () => {
                if (window.innerWidth <= mobileBreakpoint) {
                    closeMenu();
                }
            });
        });

        window.addEventListener("resize", () => {
            if (window.innerWidth > mobileBreakpoint) {
                closeMenu();
            }
        });

        navbar.dataset.responsiveInit = "true";
    });
}

function checkLogin() {
    const user = getStoredUser();
    if (!user || !user.user_id) {
        clearStoredUser();
        window.location.href = "login.html";
        return null;
    }
    return user;
}

async function apiCall(url, method = "GET", body = null, config = {}) {
    const { silent = false } = config;
    const targetUrl = url.startsWith("http") ? url : `${API_BASE_URL}${url}`;
    const options = {
        method,
        credentials: "include",
        headers: {
            "Content-Type": "application/json",
        },
    };

    if (body !== null) {
        options.body = JSON.stringify(body);
    }

    let response;
    try {
        response = await fetch(targetUrl, options);
    } catch (networkError) {
        const error = new Error("Unable to reach the server. Check backend connection.");
        error.isNotified = !silent;
        if (!silent) {
            showToast(error.message, "error");
        }
        throw error;
    }

    let data = {};
    try {
        data = await response.json();
    } catch (parseError) {
        data = {};
    }

    if (!response.ok) {
        const message = data.error || data.message || "Request failed";
        const error = new Error(message);

        if (response.status === 401 && !window.location.pathname.endsWith("login.html")) {
            clearStoredUser();
            if (!silent) {
                showToast("Please log in again", "error");
            }
            setTimeout(() => {
                window.location.href = "login.html";
            }, 650);
            error.isNotified = true;
            throw error;
        }

        if (!silent) {
            showToast(message, "error");
            error.isNotified = true;
        }

        throw error;
    }

    return data;
}

const toastHistory = new Map();

function showToast(message, type = "info") {
    const text = String(message || "").trim();
    if (!text) {
        return;
    }

    const now = Date.now();
    const duplicateKey = `${type}:${text}`;
    const lastShown = toastHistory.get(duplicateKey) || 0;
    if (now - lastShown < 900) {
        return;
    }
    toastHistory.set(duplicateKey, now);

    let container = document.querySelector(".toast-container");
    if (!container) {
        container = document.createElement("div");
        container.className = "toast-container";
        document.body.appendChild(container);
    }

    const toast = document.createElement("div");
    toast.className = `toast toast-${type}`;
    toast.textContent = text;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = "0";
        toast.style.transform = "translateY(-8px)";
        toast.style.transition = "opacity 0.18s ease, transform 0.18s ease";
    }, 3200);

    setTimeout(() => {
        toast.remove();
        if (!container.childElementCount) {
            container.remove();
        }
    }, 3450);
}

function setButtonLoading(button, isLoading, loadingText = "Please wait...") {
    if (!button) {
        return;
    }

    if (isLoading) {
        button.dataset.originalText = button.textContent;
        button.dataset.loading = "true";
        const spinner = document.createElement("span");
        spinner.className = "button-spinner";
        spinner.setAttribute("aria-hidden", "true");
        button.replaceChildren(spinner, document.createTextNode(loadingText));
        button.disabled = true;
    } else {
        delete button.dataset.loading;
        button.textContent = button.dataset.originalText || button.textContent;
        const form = button.closest("form");
        button.disabled = form ? !form.checkValidity() : false;
    }
}

function bindRequiredForm(form, submitButton) {
    if (!form || !submitButton) {
        return;
    }

    const updateState = () => {
        if (submitButton.dataset.loading === "true") {
            return;
        }

        const requiredFields = Array.from(form.querySelectorAll("[required]"));
        const hasEmptyRequiredField = requiredFields.some((field) => !String(field.value || "").trim());
        submitButton.disabled = hasEmptyRequiredField || !form.checkValidity();
    };

    form.addEventListener("input", updateState);
    form.addEventListener("change", updateState);
    updateState();
}

let activeRatingTxnId = null;
let selectedRatingScore = 0;

function ensureRatingModal() {
    if (document.getElementById("ratingModal")) {
        return;
    }

    const modal = document.createElement("div");
    modal.className = "modal-backdrop";
    modal.id = "ratingModal";
    modal.setAttribute("role", "dialog");
    modal.setAttribute("aria-modal", "true");
    modal.setAttribute("aria-labelledby", "ratingModalTitle");
    modal.innerHTML = `
        <section class="modal rating-modal">
            <div class="modal-header">
                <div>
                    <h2 id="ratingModalTitle">Rate Transaction</h2>
                    <p>Submit a 1-5 rating for the other party.</p>
                </div>
                <button class="icon-button" type="button" id="closeRatingModal" aria-label="Close rating modal">&times;</button>
            </div>
            <div class="modal-body">
                <form id="ratingForm">
                    <div class="star-rating" id="starRating" aria-label="Choose rating">
                        <button type="button" class="star-button" data-score="1" aria-label="1 star">&#9733;</button>
                        <button type="button" class="star-button" data-score="2" aria-label="2 stars">&#9733;</button>
                        <button type="button" class="star-button" data-score="3" aria-label="3 stars">&#9733;</button>
                        <button type="button" class="star-button" data-score="4" aria-label="4 stars">&#9733;</button>
                        <button type="button" class="star-button" data-score="5" aria-label="5 stars">&#9733;</button>
                    </div>
                    <div class="form-group">
                        <label for="ratingComment">Comment</label>
                        <textarea id="ratingComment" rows="3" maxlength="500" placeholder="Optional note about the exchange"></textarea>
                    </div>
                    <div class="form-actions">
                        <button class="button button-ghost" type="button" id="cancelRating">Cancel</button>
                        <button class="button button-primary" type="submit" id="submitRating" disabled>Submit Rating</button>
                    </div>
                </form>
            </div>
        </section>
    `;

    document.body.appendChild(modal);

    document.getElementById("closeRatingModal").addEventListener("click", closeRatingModal);
    document.getElementById("cancelRating").addEventListener("click", closeRatingModal);
    modal.addEventListener("click", (event) => {
        if (event.target.id === "ratingModal") {
            closeRatingModal();
        }
    });

    document.querySelectorAll("#starRating .star-button").forEach((button) => {
        button.addEventListener("click", () => {
            selectedRatingScore = Number(button.dataset.score);
            renderSelectedStars();
        });
    });

    document.getElementById("ratingForm").addEventListener("submit", submitRating);
}

function openRatingModal(txnId) {
    if (!txnId) {
        return;
    }

    ensureRatingModal();
    activeRatingTxnId = txnId;
    selectedRatingScore = 0;
    document.getElementById("ratingComment").value = "";
    renderSelectedStars();
    document.getElementById("ratingModal").classList.add("open");
    document.querySelector("#starRating .star-button").focus();
}

function closeRatingModal() {
    const modal = document.getElementById("ratingModal");
    if (modal) {
        modal.classList.remove("open");
    }
}

function renderSelectedStars() {
    document.querySelectorAll("#starRating .star-button").forEach((button) => {
        button.classList.toggle("selected", Number(button.dataset.score) <= selectedRatingScore);
    });
    const submitButton = document.getElementById("submitRating");
    if (submitButton && submitButton.dataset.loading !== "true") {
        submitButton.disabled = selectedRatingScore < 1;
    }
}

async function submitRating(event) {
    event.preventDefault();
    if (!activeRatingTxnId || selectedRatingScore < 1) {
        showToast("Choose a star rating first", "error");
        return;
    }

    const button = document.getElementById("submitRating");
    setButtonLoading(button, true, "Submitting...");
    try {
        await apiCall("/rate", "POST", {
            txn_id: activeRatingTxnId,
            score: selectedRatingScore,
            comment: document.getElementById("ratingComment").value.trim(),
        });
        showToast("Rating submitted", "success");
        closeRatingModal();
    } catch (error) {
        showToast(error.message, "error");
    } finally {
        setButtonLoading(button, false);
        renderSelectedStars();
    }
}

function formatNumber(value, fractionDigits = 0) {
    const number = Number(value || 0);
    return number.toLocaleString("en-IN", {
        minimumFractionDigits: fractionDigits,
        maximumFractionDigits: fractionDigits,
    });
}

function formatDate(value) {
    if (!value) {
        return "-";
    }
    return new Date(value).toLocaleDateString("en-IN", {
        day: "2-digit",
        month: "short",
        year: "numeric",
    });
}

function formatPrice(value) {
    if (value === null || value === undefined || value === "") {
        return "-";
    }
    return `Rs ${formatNumber(value, 2)}`;
}

function escapeHtml(value) {
    return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

function statusBadge(value) {
    const text = String(value ?? "").trim();
    if (!text) {
        return "";
    }
    const normalized = text.toLowerCase().replace(/\s+/g, "-");
    return `<span class="badge badge-${escapeHtml(normalized)}">${escapeHtml(text)}</span>`;
}

function categoryTone(category) {
    const normalized = String(category || "").toLowerCase();
    if (normalized.includes("metal")) {
        return "tone-metal";
    }
    if (normalized.includes("polymer")) {
        return "tone-polymer";
    }
    if (normalized.includes("bio")) {
        return "tone-bio";
    }
    if (normalized.includes("industrial")) {
        return "tone-industrial";
    }
    if (normalized.includes("recyclable") || normalized.includes("fabric")) {
        return "tone-recycle";
    }
    return "tone-neutral";
}

function materialCell(name, category, detail = "") {
    const initial = escapeHtml(String(name || "?").trim().slice(0, 1).toUpperCase() || "?");
    const detailHtml = detail ? `<span>${escapeHtml(detail)}</span>` : "";
    return `
        <div class="material-cell">
            <span class="material-avatar ${categoryTone(category)}">${initial}</span>
            <span class="material-copy">
                <strong>${escapeHtml(name)}</strong>
                <span>${escapeHtml(category)}</span>
                ${detailHtml}
            </span>
        </div>
    `;
}

let notificationPollTimer = null;
let notificationVisibilityHooked = false;

function ensureNotificationBadge() {
    const navActions = document.querySelector(".app-shell .navbar .nav-actions");
    if (!navActions) {
        return null;
    }

    let holder = navActions.querySelector(".sidebar-notif");
    if (!holder) {
        holder = document.createElement("div");
        holder.className = "sidebar-notif";
        holder.innerHTML = 'Alerts <span class="notif-badge is-zero" id="sidebarNotifBadge">0</span>';
        navActions.prepend(holder);
    }

    return holder.querySelector("#sidebarNotifBadge");
}

async function refreshNotificationCount() {
    const badge = ensureNotificationBadge();
    if (!badge) {
        return;
    }

    try {
        const data = await apiCall("/notifications", "GET", null, { silent: true });
        const count = Array.isArray(data.notifications) ? data.notifications.length : 0;
        badge.textContent = String(count);
        badge.classList.toggle("is-zero", count === 0);
    } catch (error) {
        // Silent polling avoids repeated error toasts during temporary network issues.
    }
}

function startNotificationPolling() {
    if (!document.querySelector(".app-shell .navbar")) {
        return;
    }

    if (notificationPollTimer) {
        window.clearInterval(notificationPollTimer);
    }

    refreshNotificationCount();
    notificationPollTimer = window.setInterval(refreshNotificationCount, 30000);

    if (!notificationVisibilityHooked) {
        document.addEventListener("visibilitychange", () => {
            if (!document.hidden) {
                refreshNotificationCount();
            }
        });
        notificationVisibilityHooked = true;
    }
}

initResponsiveNav();
setActiveNav();
startNotificationPolling();
window.showToast = showToast;
