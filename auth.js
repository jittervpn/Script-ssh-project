/* ============================================================
   JitterX Panel Cloud — portada y acceso
   ============================================================ */

mountChrome();

const existing = Session.get();
if (existing && existing.token) location.replace("dashboard.html");

/* ---------- Consola: escribe registros de zona en bucle ---------- */
const SAMPLES = [
  { host: "mi-demo", type: "A",     value: "203.0.113.42",         note: "; apunta a tu VPS" },
  { host: "tienda",  type: "CNAME", value: "mi-tienda.vercel.app", note: "; apunta a tu despliegue" },
  { host: "api-v2",  type: "A",     value: "198.51.100.7",         note: "; proxy naranja activado" },
  { host: "verify",  type: "TXT",   value: '"jitterx-site=ok"',    note: "; verificación de servicio" }
];

const hostEl = document.getElementById("typeHost");
const noteEl = document.getElementById("typeNote");
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function renderLine(s, typed) {
  const pad = " ".repeat(Math.max(1, 20 - typed.length - CFG.rootDomain.length));
  hostEl.innerHTML =
    '<span class="console__h">' + escapeHtml(typed) + "." + escapeHtml(CFG.rootDomain) + '.</span>' + pad +
    '<span class="console__c">IN</span>  <span class="console__k">' + s.type + '</span>  ' +
    '<span class="console__v">' + escapeHtml(s.value) + '</span>';
}

async function typeLoop() {
  if (!hostEl) return;
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  if (reduceMotion) {
    renderLine(SAMPLES[0], SAMPLES[0].host);
    noteEl.textContent = SAMPLES[0].note;
    return;
  }
  let i = 0;
  while (true) {
    const s = SAMPLES[i % SAMPLES.length];
    noteEl.textContent = "";
    for (let c = 1; c <= s.host.length; c++) { renderLine(s, s.host.slice(0, c)); await sleep(85); }
    await sleep(320);
    noteEl.textContent = s.note;
    await sleep(2400);
    for (let c = s.host.length; c >= 0; c--) { renderLine(s, s.host.slice(0, c)); await sleep(35); }
    noteEl.textContent = "";
    i++;
  }
}
typeLoop();

/* ---------- Pestañas ---------- */
const loginForm = $("#loginForm");
const registerForm = $("#registerForm");

$$(".tab").forEach(tab => tab.addEventListener("click", () => {
  $$(".tab").forEach(x => x.classList.toggle("is-active", x === tab));
  const isLogin = tab.dataset.tab === "login";
  loginForm.hidden = !isLogin;
  registerForm.hidden = isLogin;
  $("#loginError").textContent = "";
  $("#registerError").textContent = "";
}));

/* ---------- Fuerza de contraseña ---------- */
const pwColors = ["var(--alert)", "var(--alert)", "var(--signal)", "var(--live)", "var(--live)"];
const pwWords = {
  es: ["muy débil", "débil", "aceptable", "buena", "excelente"],
  en: ["very weak", "weak", "fair", "good", "excellent"]
};
const pwInput = $("#rg-pass");
if (pwInput) pwInput.addEventListener("input", e => {
  const v = e.target.value;
  const score = passwordScore(v);
  const meter = $("#pwMeter");
  meter.style.width = v ? ((score + 1) * 20) + "%" : "0";
  meter.style.background = pwColors[score];
  $("#pwHint").textContent = v
    ? "Fuerza: " + (pwWords[LANG] || pwWords.es)[score] + "."
    : "Mezcla mayúsculas, números y algún símbolo.";
});

/* ---------- Envíos ---------- */
function busy(btn, on, label) {
  btn.disabled = on;
  btn.innerHTML = on ? '<span class="spinner"></span> Un momento…' : label;
}

loginForm.addEventListener("submit", async e => {
  e.preventDefault();
  const btn = $("#loginBtn"), err = $("#loginError");
  err.textContent = "";
  const email = $("#li-email").value.trim();
  const password = $("#li-pass").value;
  if (!email || !password) { err.textContent = "Rellena los dos campos."; return; }
  busy(btn, true);
  try {
    const s = await API.login({ email: email, password: password });
    Session.set(s);
    location.href = "dashboard.html";
  } catch (ex) {
    err.textContent = ex.message;
    busy(btn, false, "Entrar al panel");
  }
});

registerForm.addEventListener("submit", async e => {
  e.preventDefault();
  const btn = $("#registerBtn"), err = $("#registerError");
  err.textContent = "";
  const name = $("#rg-name").value.trim();
  const email = $("#rg-email").value.trim();
  const password = $("#rg-pass").value;
  if (!$("#rg-terms").checked) { err.textContent = "Confirma que aceptas la caducidad."; return; }
  if (password.length < 8) { err.textContent = "La contraseña necesita 8 caracteres como mínimo."; return; }
  busy(btn, true);
  try {
    const s = await API.register({ name: name, email: email, password: password });
    Session.set(s);
    toast("Cuenta creada", "Ya puedes reservar tu primer subdominio.", "ok");
    setTimeout(() => location.href = "dashboard.html", 500);
  } catch (ex) {
    err.textContent = ex.message;
    busy(btn, false, "Crear mi cuenta");
  }
});

/* ---------- Modo demostración ---------- */
const modeNote = $("#modeNote");
if (API.demo) {
  $("#demoNotice").hidden = false;
  modeNote.textContent = "modo demostración · sin backend conectado";
  $("#fillDemo").addEventListener("click", () => {
    $$(".tab").filter(t => t.dataset.tab === "login")[0].click();
    $("#li-email").value = CFG.demoAdminEmail;
    $("#li-pass").value = CFG.demoAdminPassword;
    toast("Cuenta de prueba lista", "Pulsa Entrar al panel.", "info");
  });
} else {
  modeNote.textContent = "conectado a " + CFG.apiBase.replace(/^https?:\/\//, "");
}
