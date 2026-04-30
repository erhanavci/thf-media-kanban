import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = "https://zzannmvjybpknetszqpb.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6YW5ubXZqeWJwa25ldHN6cXBiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NDA4MTAsImV4cCI6MjA5MzExNjgxMH0.MvZi6BG896cfzz30eUOC7lWmRncIjCSZiABJUA-tMfA";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const columns = [
  { id: "plan", day: "Pazartesi", title: "Strateji & Planlama", phase: "Planla", tone: "tone-blue" },
  { id: "start", day: "Salı", title: "Üretim Başlangıcı", phase: "Üret", tone: "tone-gold" },
  { id: "production", day: "Çarşamba", title: "İçerik Üretimi", phase: "Üret", tone: "tone-orange" },
  { id: "approval", day: "Perşembe", title: "Onay & Hazırlık", phase: "Hazırla", tone: "tone-violet" },
  { id: "publish", day: "Cuma", title: "Yayın Başlangıcı", phase: "Yayınla", tone: "tone-rose" },
  { id: "live", day: "Cumartesi", title: "Canlı Operasyon", phase: "Canlı Yönet", tone: "tone-red" },
  { id: "post", day: "Cumartesi", title: "Yayın Paketi", phase: "Yayınla", tone: "tone-steel" },
  { id: "analysis", day: "Pazar", title: "Analiz & Optimizasyon", phase: "Analiz Et", tone: "tone-green" },
];

const importedTasks = [
  ["2026-03-02", "Championship announcement post (Graphic animation) v1 + Social ads", "publish", "Mar"],
  ["2026-03-11", "Championship announcement post (Graphic animation) v2 + Social ads", "publish", "Mar"],
  ["2026-03-16", "Championship announcement post (Graphic animation) v3 + Social ads", "publish", "Mar"],
  ["2026-03-27", "Championship announcement post (Graphic animation) v4 + Social ads", "publish", "Mar"],
  ["2026-04-03", "Championship announcement post (Graphic animation) v5 + Social ads", "publish", "Apr"],
  ["2026-04-07", "Q&A with athletes v1", "plan", "Apr"],
  ["2026-04-16", "Championship announcement post (Graphic animation) v6 + Social ads", "publish", "Apr"],
  ["2026-04-22", "Q&A with athletes v2", "plan", "Apr"],
  ["2026-05-04", "Official promotional video", "production", "May"],
  ["2026-05-11", "Official mascot", "plan", "May"],
  ["2026-05-18", "Ticket sales announcement", "publish", "May"],
  ["2026-05-29", "Ticket giveaway", "publish", "May"],
  ["2026-06-05", "Influencer video v1", "production", "Jun"],
  ["2026-06-10", "Influencer video v2", "production", "Jun"],
  ["2026-06-19", "Volunteer announcement", "publish", "Jun"],
  ["2026-06-24", "Influencer video v3", "production", "Jun"],
  ["2026-07-03", "Content about handball events in Antalya", "production", "Jul"],
  ["2026-07-07", "Content about handball events in Antalya", "production", "Jul"],
  ["2026-07-17", "Content about handball events in Antalya", "production", "Jul"],
  ["2026-07-22", "Content about handball events in Antalya", "production", "Jul"],
  ["2026-09-04", "Official song announcement", "publish", "Sep"],
  ["2026-09-07", "The mascot's school visit", "publish", "Sep"],
  ["2026-09-18", "The mascot's shopping mall visit", "publish", "Sep"],
  ["2026-09-23", "The mascot's Antalya Sports Hall visit", "live", "Sep"],
  ["2026-10-02", "Turkey National Team's player's talks at school", "publish", "Oct"],
  ["2026-10-16", "Turkey National Team's player's talks at school", "publish", "Oct"],
  ["2026-11-02", "Content for visuals prepared in Antalya regarding the European Championship.", "production", "Nov"],
  ["2026-11-20", "Content for visuals prepared in Antalya regarding the European Championship.", "production", "Nov"],
];

let session = null;
let currentProfile = null;
let profiles = [];
let tasks = [];
let selectedTaskId = "";
let activeColumn = "all";
let calendarMonth = "2026-03";
let pendingFiles = [];
let pendingVoices = [];
let recorder = null;
let recordedChunks = [];

const authScreen = document.getElementById("auth-screen");
const appScreen = document.getElementById("app-screen");
const authMessage = document.getElementById("auth-message");
const board = document.getElementById("kanban-board");
const taskForm = document.getElementById("task-form");
const userForm = document.getElementById("user-form");
const recordButton = document.getElementById("record-button");
const voiceStatus = document.getElementById("voice-status");

boot();

async function boot() {
  const { data } = await supabase.auth.getSession();
  session = data.session;
  wireEvents();
  await renderShell();

  supabase.auth.onAuthStateChange(async (_event, nextSession) => {
    session = nextSession;
    await renderShell();
  });
}

function wireEvents() {
  document.getElementById("login-tab").addEventListener("click", () => setAuthMode("login"));
  document.getElementById("register-tab").addEventListener("click", () => setAuthMode("register"));
  document.getElementById("login-form").addEventListener("submit", login);
  document.getElementById("register-form").addEventListener("submit", register);
  document.getElementById("logout-button").addEventListener("click", () => supabase.auth.signOut());
  document.getElementById("show-all-button").addEventListener("click", () => {
    activeColumn = "all";
    renderBoard();
  });
  document.getElementById("new-task-button").addEventListener("click", () => {
    selectedTaskId = "";
    pendingFiles = [];
    pendingVoices = [];
    renderEditor();
    document.getElementById("task-title").focus();
  });
  document.getElementById("clear-button").addEventListener("click", () => {
    selectedTaskId = "";
    pendingFiles = [];
    pendingVoices = [];
    taskForm.reset();
    renderEditor();
  });
  document.getElementById("calendar-prev").addEventListener("click", () => moveCalendarMonth(-1));
  document.getElementById("calendar-next").addEventListener("click", () => moveCalendarMonth(1));
  document.getElementById("task-files").addEventListener("change", (event) => {
    pendingFiles = Array.from(event.target.files || []);
    renderAssets(getSelectedTask());
  });
  taskForm.addEventListener("submit", saveTask);
  userForm.addEventListener("submit", addProfile);
  recordButton.addEventListener("click", toggleRecording);
  board.addEventListener("click", handleBoardClick);
  board.addEventListener("dragstart", handleDragStart);
  board.addEventListener("dragover", (event) => {
    if (event.target.closest("[data-drop-column]")) event.preventDefault();
  });
  board.addEventListener("drop", handleDrop);
  document.getElementById("calendar-grid").addEventListener("click", (event) => {
    const button = event.target.closest("[data-calendar-task]");
    if (!button) return;
    selectedTaskId = button.dataset.calendarTask;
    pendingFiles = [];
    pendingVoices = [];
    renderAll();
    document.getElementById("editor-title").scrollIntoView({ behavior: "smooth", block: "start" });
  });
}

async function login(event) {
  event.preventDefault();
  setAuthMessage("Giriş yapılıyor...");
  const { error } = await supabase.auth.signInWithPassword({
    email: document.getElementById("login-email").value.trim(),
    password: document.getElementById("login-password").value,
  });
  if (error) setAuthMessage(error.message);
}

async function register(event) {
  event.preventDefault();
  setAuthMessage("Üyelik oluşturuluyor...");
  const fullName = document.getElementById("register-name").value.trim();
  const role = document.getElementById("register-role").value.trim();
  const { data, error } = await supabase.auth.signUp({
    email: document.getElementById("register-email").value.trim(),
    password: document.getElementById("register-password").value,
    options: { data: { full_name: fullName, role } },
  });

  if (error) {
    setAuthMessage(error.message);
    return;
  }

  if (data.user) {
    await supabase
      .from("profiles")
      .upsert({ auth_user_id: data.user.id, full_name: fullName, role }, { onConflict: "auth_user_id" });
  }

  setAuthMessage(data.session ? "" : "Üyelik oluşturuldu. Supabase email onayı açıksa e-postanı onaylayıp giriş yap.");
}

async function renderShell() {
  authScreen.classList.toggle("app-hidden", Boolean(session));
  appScreen.classList.toggle("app-hidden", !session);
  if (!session) return;

  await ensureProfile();
  await seedImportedTasks();
  await loadData();
  document.getElementById("current-user-label").textContent =
    `${currentProfile?.full_name || session.user.email} • ${currentProfile?.role || "Ekip"}`;
  renderAll();
}

async function ensureProfile() {
  const { data } = await supabase
    .from("profiles")
    .select("*")
    .eq("auth_user_id", session.user.id)
    .maybeSingle();
  if (data) {
    currentProfile = data;
    return;
  }
  const meta = session.user.user_metadata || {};
  const fallback = {
    auth_user_id: session.user.id,
    full_name: meta.full_name || session.user.email,
    role: meta.role || "Ekip",
  };
  const { data: inserted } = await supabase
    .from("profiles")
    .upsert(fallback, { onConflict: "auth_user_id" })
    .select("*")
    .single();
  currentProfile = inserted || fallback;
}

async function seedImportedTasks() {
  const rows = importedTasks.map(([date, title, column, sheet]) => ({
    title,
    description: `${title}\nKaynak: EHF Women's Euro 2026.xlsx / ${sheet}`,
    status: column,
    task_date: date,
    import_key: `${date}|${title}`,
    created_by: session.user.id,
  }));
  await supabase.from("tasks").upsert(rows, { onConflict: "import_key", ignoreDuplicates: true });
}

async function loadData() {
  const [profileResult, taskResult, assigneeResult, fileResult, voiceResult] = await Promise.all([
    supabase.from("profiles").select("*").order("full_name"),
    supabase.from("tasks").select("*").order("task_date", { ascending: true, nullsFirst: false }),
    supabase.from("task_assignees").select("*"),
    supabase.from("task_files").select("*"),
    supabase.from("voice_notes").select("*"),
  ]);

  if (taskResult.error) {
    setAuthMessage(`Database okunamadı: ${taskResult.error.message}`);
    return;
  }

  profiles = profileResult.data || [];
  const assigneesByTask = groupBy(assigneeResult.data || [], "task_id");
  const filesByTask = groupBy(fileResult.data || [], "task_id");
  const voicesByTask = groupBy(voiceResult.data || [], "task_id");
  tasks = (taskResult.data || []).map((task) => ({
    id: task.id,
    column: task.status,
    title: task.title,
    desc: task.description || "",
    date: task.task_date || "",
    assignees: (assigneesByTask[task.id] || []).map((row) => row.user_id),
    files: filesByTask[task.id] || [],
    voices: voicesByTask[task.id] || [],
  }));
}

function renderAll() {
  renderSelectors();
  renderUsers();
  renderBoard();
  renderCalendar();
  renderEditor();
}

function renderSelectors() {
  document.getElementById("task-column").innerHTML = columns
    .map((column) => `<option value="${column.id}">${column.day} - ${column.title}</option>`)
    .join("");
  document.getElementById("task-user").innerHTML = profiles
    .map((profile) => `<option value="${profile.id}">${escapeHtml(profile.full_name)} / ${escapeHtml(profile.role || "Ekip")}</option>`)
    .join("");
}

function renderUsers() {
  document.getElementById("user-list").innerHTML = profiles
    .map((profile) => `<span class="user-pill">${escapeHtml(profile.full_name)} / ${escapeHtml(profile.role || "Ekip")}</span>`)
    .join("");
}

function renderBoard() {
  const active = columns.find((column) => column.id === activeColumn);
  document.getElementById("active-view-title").textContent = active ? active.title : "Tüm Pipeline";
  const visibleColumns = activeColumn === "all" ? columns : columns.filter((column) => column.id === activeColumn);
  board.innerHTML = visibleColumns
    .map((column) => {
      const columnTasks = tasks.filter((task) => task.column === column.id);
      return `
        <section class="kanban-column" data-column="${column.id}">
          <button class="column-heading ${column.tone}" type="button" data-filter="${column.id}">
            <span>${column.day}</span>
            <strong>${column.title}</strong>
            <em>${column.phase}</em>
          </button>
          <div class="task-stack" data-drop-column="${column.id}">
            ${columnTasks.length ? columnTasks.map(renderTaskCard).join("") : `<div class="empty-state">Bu kolonda görev yok.</div>`}
          </div>
        </section>
      `;
    })
    .join("");
}

function renderTaskCard(task) {
  const selected = task.id === selectedTaskId ? "selected" : "";
  return `
    <button class="task-card ${selected}" type="button" draggable="true" data-task="${task.id}">
      <strong>${escapeHtml(task.title)}</strong>
      <span>${escapeHtml(task.desc || "Açıklama yok")}</span>
      <div class="task-card-meta">
        <small>${escapeHtml(labelAssignees(task.assignees))}</small>
        <small>${task.date ? formatDate(task.date) : "Tarihsiz"} • ${task.files.length} dosya • ${task.voices.length} ses</small>
      </div>
    </button>
  `;
}

function renderCalendar() {
  const [year, month] = calendarMonth.split("-").map(Number);
  const firstDay = new Date(year, month - 1, 1);
  const dayCount = new Date(year, month, 0).getDate();
  const leadingBlanks = (firstDay.getDay() + 6) % 7;
  const cells = [];
  document.getElementById("calendar-title").textContent = new Intl.DateTimeFormat("tr-TR", {
    month: "long",
    year: "numeric",
  }).format(firstDay);

  for (let index = 0; index < leadingBlanks; index += 1) cells.push(`<div class="calendar-day muted"></div>`);
  for (let day = 1; day <= dayCount; day += 1) {
    const date = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
    const dayTasks = tasks.filter((task) => task.date === date);
    cells.push(`
      <div class="calendar-day ${dayTasks.length ? "has-tasks" : ""}">
        <div class="calendar-date">${day}</div>
        <div class="calendar-tasks">
          ${dayTasks.map((task) => `<button class="calendar-task" type="button" data-calendar-task="${task.id}">${escapeHtml(task.title)}</button>`).join("")}
        </div>
      </div>
    `);
  }
  document.getElementById("calendar-grid").innerHTML = cells.join("");
}

function renderEditor() {
  const task = getSelectedTask();
  document.getElementById("editor-title").textContent = task ? "Görevi Düzenle" : "Yeni Görev";
  document.getElementById("task-id").value = task?.id || "";
  document.getElementById("task-title").value = task?.title || "";
  document.getElementById("task-desc").value = task?.desc || "";
  document.getElementById("task-date").value = task?.date || "";
  document.getElementById("task-column").value = task?.column || (activeColumn !== "all" ? activeColumn : "plan");
  setSelectedAssignees(task?.assignees || []);
  renderAssets(task);
}

function renderAssets(task) {
  const files = [...(task?.files || []), ...pendingFiles.map((file) => ({ file_name: file.name, file_type: file.type }))];
  const voices = [...(task?.voices || []), ...pendingVoices.map((voice) => ({ file_name: voice.name }))];
  document.getElementById("asset-list").innerHTML = `
    <div>
      <strong>Dosyalar</strong>
      ${files.length ? files.map(renderFile).join("") : `<p>Henüz dosya yok.</p>`}
    </div>
    <div>
      <strong>Sesli Notlar</strong>
      ${voices.length ? voices.map(renderVoice).join("") : `<p>Henüz sesli not yok.</p>`}
    </div>
  `;
}

function renderFile(file) {
  const href = file.file_url || "#";
  return `<a class="asset-link" href="${href}" target="_blank" rel="noreferrer"><span>${escapeHtml(file.file_name || "Dosya")}</span><small>${escapeHtml(file.file_type || "")}</small></a>`;
}

function renderVoice(voice) {
  return `<div class="voice-note">${voice.audio_url ? `<audio controls src="${voice.audio_url}"></audio>` : ""}<small>${escapeHtml(voice.file_name || "Sesli not")}</small></div>`;
}

function handleBoardClick(event) {
  const heading = event.target.closest("[data-filter]");
  const card = event.target.closest("[data-task]");
  if (heading) {
    activeColumn = heading.dataset.filter;
    renderBoard();
  }
  if (card) {
    selectedTaskId = card.dataset.task;
    pendingFiles = [];
    pendingVoices = [];
    renderAll();
  }
}

function handleDragStart(event) {
  const card = event.target.closest("[data-task]");
  if (card) event.dataTransfer.setData("text/plain", card.dataset.task);
}

async function handleDrop(event) {
  const dropZone = event.target.closest("[data-drop-column]");
  const taskId = event.dataTransfer.getData("text/plain");
  if (!dropZone || !taskId) return;
  await supabase.from("tasks").update({ status: dropZone.dataset.dropColumn }).eq("id", taskId);
  await loadData();
  renderAll();
}

async function saveTask(event) {
  event.preventDefault();
  const id = document.getElementById("task-id").value;
  const payload = {
    title: document.getElementById("task-title").value.trim(),
    description: document.getElementById("task-desc").value.trim(),
    task_date: document.getElementById("task-date").value || null,
    status: document.getElementById("task-column").value,
    created_by: session.user.id,
  };

  const result = id
    ? await supabase.from("tasks").update(payload).eq("id", id).select("id").single()
    : await supabase.from("tasks").insert(payload).select("id").single();

  if (result.error) {
    alert(result.error.message);
    return;
  }

  const taskId = result.data.id;
  await supabase.from("task_assignees").delete().eq("task_id", taskId);
  const assignees = getSelectedAssignees().map((userId) => ({ task_id: taskId, user_id: userId }));
  if (assignees.length) await supabase.from("task_assignees").insert(assignees);
  await uploadPendingAssets(taskId);

  selectedTaskId = taskId;
  pendingFiles = [];
  pendingVoices = [];
  document.getElementById("task-files").value = "";
  await loadData();
  renderAll();
}

async function uploadPendingAssets(taskId) {
  for (const file of pendingFiles) {
    const path = `${taskId}/files/${crypto.randomUUID()}-${safeName(file.name)}`;
    const { error } = await supabase.storage.from("task-assets").upload(path, file, { upsert: true });
    if (error) throw error;
    const { data } = supabase.storage.from("task-assets").getPublicUrl(path);
    await supabase.from("task_files").insert({
      task_id: taskId,
      file_url: data.publicUrl,
      file_name: file.name,
      file_type: file.type,
    });
  }

  for (const voice of pendingVoices) {
    const path = `${taskId}/voice/${crypto.randomUUID()}-${safeName(voice.name)}.webm`;
    const { error } = await supabase.storage.from("task-assets").upload(path, voice.blob, { upsert: true });
    if (error) throw error;
    const { data } = supabase.storage.from("task-assets").getPublicUrl(path);
    await supabase.from("voice_notes").insert({
      task_id: taskId,
      audio_url: data.publicUrl,
      file_name: voice.name,
      created_by: session.user.id,
    });
  }
}

async function addProfile(event) {
  event.preventDefault();
  const value = document.getElementById("user-name").value.trim();
  if (!value) return;
  const [fullName, role = "Ekip"] = value.split("/").map((part) => part.trim());
  await supabase.from("profiles").insert({ full_name: fullName, role });
  document.getElementById("user-name").value = "";
  await loadData();
  renderAll();
}

async function toggleRecording() {
  if (recorder?.state === "recording") {
    recorder.stop();
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    recordedChunks = [];
    recorder = new MediaRecorder(stream);
    recorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) recordedChunks.push(event.data);
    });
    recorder.addEventListener("stop", () => {
      stream.getTracks().forEach((track) => track.stop());
      pendingVoices.push({
        name: `Sesli not ${new Date().toLocaleTimeString("tr-TR")}`,
        blob: new Blob(recordedChunks, { type: "audio/webm" }),
      });
      recordButton.textContent = "Kayda Başla";
      voiceStatus.textContent = "Kaydedildi";
      renderAssets(getSelectedTask());
    });
    recorder.start();
    recordButton.textContent = "Kaydı Bitir";
    voiceStatus.textContent = "Kayıt alınıyor";
  } catch {
    voiceStatus.textContent = "Mikrofon izni gerekli";
  }
}

function setAuthMode(mode) {
  const isLogin = mode === "login";
  document.getElementById("login-tab").classList.toggle("active", isLogin);
  document.getElementById("register-tab").classList.toggle("active", !isLogin);
  document.getElementById("login-form").classList.toggle("hidden", !isLogin);
  document.getElementById("register-form").classList.toggle("hidden", isLogin);
  setAuthMessage("");
}

function moveCalendarMonth(delta) {
  const [year, month] = calendarMonth.split("-").map(Number);
  const next = new Date(year, month - 1 + delta, 1);
  calendarMonth = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, "0")}`;
  renderCalendar();
}

function getSelectedTask() {
  return tasks.find((task) => task.id === selectedTaskId);
}

function getSelectedAssignees() {
  return Array.from(document.getElementById("task-user").selectedOptions).map((option) => option.value);
}

function setSelectedAssignees(assignees) {
  const selected = new Set(assignees.length ? assignees : currentProfile ? [currentProfile.id] : []);
  Array.from(document.getElementById("task-user").options).forEach((option) => {
    option.selected = selected.has(option.value);
  });
}

function labelAssignees(ids) {
  if (!ids.length) return "Atanmadı";
  return ids
    .map((id) => profiles.find((profile) => profile.id === id))
    .filter(Boolean)
    .map((profile) => profile.full_name)
    .join(", ");
}

function groupBy(rows, key) {
  return rows.reduce((acc, row) => {
    acc[row[key]] ||= [];
    acc[row[key]].push(row);
    return acc;
  }, {});
}

function setAuthMessage(message) {
  authMessage.textContent = message;
}

function formatDate(date) {
  return new Intl.DateTimeFormat("tr-TR", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(`${date}T12:00:00`));
}

function safeName(name) {
  return name.toLowerCase().replace(/[^a-z0-9._-]+/g, "-");
}

function escapeHtml(value = "") {
  return String(value).replace(/[&<>"']/g, (char) => {
    const map = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" };
    return map[char];
  });
}
