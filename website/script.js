const revealEls = document.querySelectorAll(".reveal");

revealEls.forEach((el) => {
  const delay = el.getAttribute("data-delay");
  if (delay) {
    el.style.setProperty("--delay", `${delay}ms`);
  }
});

if ("IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          revealObserver.unobserve(entry.target);
        }
      });
    },
    {
      threshold: 0.2,
      rootMargin: "0px 0px -10% 0px",
    }
  );

  revealEls.forEach((el) => revealObserver.observe(el));
} else {
  revealEls.forEach((el) => el.classList.add("is-visible"));
}

const yearEl = document.getElementById("year");
if (yearEl) {
  yearEl.textContent = new Date().getFullYear();
}

const countEl = document.getElementById("download-count");
const stickyCountEl = document.getElementById("sticky-download-count");
const countKey = "stopalertDownloadCount";
const downloadButtons = document.querySelectorAll(".track-download");

function getDownloadCount() {
  try {
    return Number(localStorage.getItem(countKey) || 0);
  } catch (err) {
    return 0;
  }
}

function renderCount() {
  const text = `Downloads from this browser: ${getDownloadCount()}`;
  if (countEl) countEl.textContent = text;
  if (stickyCountEl) stickyCountEl.textContent = text;
}

downloadButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    try {
      const next = getDownloadCount() + 1;
      localStorage.setItem(countKey, String(next));
      renderCount();
    } catch (err) {
      renderCount();
    }
  });
});

renderCount();

const stickyDownload = document.getElementById("sticky-download");
if (stickyDownload) {
  const toggleStickyDownload = () => {
    const show = window.scrollY > 420;
    stickyDownload.classList.toggle("is-visible", show);
    stickyDownload.setAttribute("aria-hidden", show ? "false" : "true");
  };

  toggleStickyDownload();
  window.addEventListener("scroll", toggleStickyDownload, { passive: true });
}

const liveCtaEl = document.getElementById("live-cta");
if (liveCtaEl) {
  const baseDot = '<span class="live-dot"></span>';
  const ctaLines = [
    `${baseDot} Fast install, no sign-up, and ready for your next ride.`,
    `${baseDot} Direct APK download from this page, no store steps needed.`,
    `${baseDot} Start safer commuting today with milestone and arrival alerts.`,
  ];

  let ctaIndex = 0;
  setInterval(() => {
    ctaIndex = (ctaIndex + 1) % ctaLines.length;
    liveCtaEl.classList.add("is-swapping");
    setTimeout(() => {
      liveCtaEl.innerHTML = ctaLines[ctaIndex];
      liveCtaEl.classList.remove("is-swapping");
    }, 150);
  }, 3400);
}

const faqItems = document.querySelectorAll(".faq-item");
faqItems.forEach((item) => {
  item.addEventListener("toggle", () => {
    if (!item.open) return;
    faqItems.forEach((other) => {
      if (other !== item) other.open = false;
    });
  });
});

const metricSection = document.querySelector(".metrics");
const counters = document.querySelectorAll(".counter");

function easeOutCubic(t) {
  return 1 - Math.pow(1 - t, 3);
}

function animateCounter(el, index) {
  const target = Number(el.dataset.target || 0);
  const suffix = el.dataset.suffix || "";
  const duration = 1200 + index * 180;
  const start = performance.now();

  function step(now) {
    const elapsed = now - start;
    const progress = Math.min(elapsed / duration, 1);
    const value = Math.round(target * easeOutCubic(progress));
    const formatted = target > 999 ? value.toLocaleString() : String(value);
    el.textContent = `${formatted}${suffix}`;
    if (progress < 1) {
      requestAnimationFrame(step);
    }
  }

  requestAnimationFrame(step);
}

if (metricSection && counters.length > 0) {
  if ("IntersectionObserver" in window) {
    const metricObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          counters.forEach((counter, idx) => animateCounter(counter, idx));
          metricObserver.unobserve(entry.target);
        });
      },
      {
        threshold: 0.4,
      }
    );

    metricObserver.observe(metricSection);
  } else {
    counters.forEach((counter, idx) => animateCounter(counter, idx));
  }
}
