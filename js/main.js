/* RehoSpace Enterprise — site scripts */
(function () {
    "use strict";

    // Spinner
    window.addEventListener("load", function () {
        var spinner = document.getElementById("spinner");
        if (spinner) { setTimeout(function () { spinner.classList.remove("show"); }, 150); }
    });

    // Scroll reveal animations
    if (typeof WOW === "function") { new WOW({ offset: 60, mobile: true }).init(); }

    // Sticky header shadow + back-to-top visibility
    var header = document.querySelector(".site-header");
    var backToTop = document.querySelector(".back-to-top");
    function onScroll() {
        var y = window.scrollY || document.documentElement.scrollTop;
        if (header) { header.classList.toggle("scrolled", y > 10); }
        if (backToTop) { backToTop.style.display = y > 400 ? "flex" : "none"; }
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    if (backToTop) {
        backToTop.addEventListener("click", function (e) {
            e.preventDefault();
            window.scrollTo({ top: 0, behavior: "smooth" });
        });
    }

    // Highlight the current page in the navigation
    // Works for both local files (about.html) and Cloudflare clean URLs (/about)
    var path = (window.location.pathname.split("/").pop() || "index").toLowerCase().replace(/\.html$/, "");
    document.querySelectorAll(".navbar .nav-link").forEach(function (link) {
        var href = (link.getAttribute("href") || "").split("#")[0].toLowerCase().replace(/\.html$/, "");
        if (href === path) { link.classList.add("active"); }
    });

    // Collapse the mobile menu after clicking a link
    document.querySelectorAll(".navbar-collapse .nav-link").forEach(function (link) {
        link.addEventListener("click", function () {
            var collapse = document.getElementById("mainNav");
            if (collapse && collapse.classList.contains("show") && window.bootstrap) {
                bootstrap.Collapse.getOrCreateInstance(collapse).hide();
            }
        });
    });

    // Animated counters
    function animateCounter(el) {
        var target = parseInt(el.getAttribute("data-count"), 10) || 0;
        var suffix = el.getAttribute("data-suffix") || "";
        var duration = 1600, start = null;
        function stepFn(ts) {
            if (!start) { start = ts; }
            var p = Math.min((ts - start) / duration, 1);
            var eased = 1 - Math.pow(1 - p, 3);
            el.textContent = Math.round(target * eased).toLocaleString() + suffix;
            if (p < 1) { requestAnimationFrame(stepFn); }
        }
        requestAnimationFrame(stepFn);
    }
    var counters = document.querySelectorAll("[data-count]");
    if (counters.length) {
        if ("IntersectionObserver" in window) {
            var io = new IntersectionObserver(function (entries) {
                entries.forEach(function (entry) {
                    if (entry.isIntersecting) { animateCounter(entry.target); io.unobserve(entry.target); }
                });
            }, { threshold: 0.4 });
            counters.forEach(function (c) { io.observe(c); });
        } else {
            counters.forEach(animateCounter);
        }
    }

    // Current year in footer
    document.querySelectorAll("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });

    // Contact form: send via WhatsApp or email (no backend needed yet)
    var form = document.getElementById("contactForm");
    if (form) {
        var WA_NUMBER = "255745814072";
        var EMAIL = "info@rehospace.com";

        var sw = (document.documentElement.lang || "en").toLowerCase() === "sw";
        var L = sw
            ? { hello: "Habari RehoSpace,", name: "Jina", phone: "Simu", business: "Aina ya biashara", interest: "Ninavutiwa na", subject: "Ujumbe kutoka tovuti: " }
            : { hello: "Hello RehoSpace,", name: "Name", phone: "Phone", business: "Business type", interest: "Interested in", subject: "Website enquiry from " };

        function buildMessage() {
            var name = form.querySelector("#cName").value.trim();
            var phone = form.querySelector("#cPhone").value.trim();
            var business = form.querySelector("#cBusiness").value;
            var interest = form.querySelector("#cInterest").value;
            var message = form.querySelector("#cMessage").value.trim();
            return [
                L.hello,
                "",
                L.name + ": " + name,
                L.phone + ": " + phone,
                L.business + ": " + (business || "-"),
                L.interest + ": " + (interest || "-"),
                "",
                message
            ].join("\n");
        }

        function validate() {
            if (!form.checkValidity()) {
                form.classList.add("was-validated");
                return false;
            }
            return true;
        }

        var waBtn = document.getElementById("sendWhatsApp");
        var mailBtn = document.getElementById("sendEmail");
        if (waBtn) {
            waBtn.addEventListener("click", function () {
                if (!validate()) { return; }
                window.open("https://wa.me/" + WA_NUMBER + "?text=" + encodeURIComponent(buildMessage()), "_blank", "noopener");
            });
        }
        if (mailBtn) {
            mailBtn.addEventListener("click", function () {
                if (!validate()) { return; }
                var subject = L.subject + form.querySelector("#cName").value.trim();
                window.location.href = "mailto:" + EMAIL + "?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(buildMessage());
            });
        }
    }
})();
