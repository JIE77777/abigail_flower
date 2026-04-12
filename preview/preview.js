const defaultPreviewConfig = {
  titleLine: '距离 8.31',
  targetMonth: 8,
  targetDay: 31,
  taglineCountMin: 1,
  taglineCountMax: 1,
  easterEggDailyChance: 28,
  showEnglishFirst: true,
  taglineWeights: {
    bright: 3,
    reminders: 2,
    playful: 2,
    wendy: 2,
    cookie: 5,
  },
  easterWeights: {
    always: 1,
    thursday: 2,
    weekend: 2,
    august: 3,
    final30: 4,
    final10: 6,
    milestones: 6,
    cookie: 3,
  },
};

const fallbackData = {
  taglines: {
    bright: [['你今天是最棒的！']],
    reminders: [['今天记得喝水！']],
    playful: [['啊啊啊啊啊啊啊啊']],
    wendy: [['Everything dies.', '万物皆有一死。']],
    cookie: [['Cookie 说你今天超棒']],
  },
  easterEggs: {
    always: [['隐藏彩蛋：今天适合奖励自己一下']],
  },
};

const milestoneDays = new Set([200, 160, 150, 120, 100, 60, 50, 30, 10, 7, 3, 1]);
const rerollStorageKey = 'abigail-flower-preview-reroll-seed';
const rerollDateKey = 'abigail-flower-preview-reroll-date';
const simulatedDateStorageKey = 'abigail-flower-preview-simulated-date';
const pagesStorageKey = 'abigail-flower-preview-pages';
const selectedPageStorageKey = 'abigail-flower-preview-selected-page';

const sourceManifest = {
  taglines: ['bright', 'cookie', 'playful', 'reminders', 'wendy'],
  easterEggs: ['always', 'august', 'cookie', 'final10', 'final30', 'milestones', 'thursday', 'weekend'],
};

function deepClone(value) {
  return JSON.parse(JSON.stringify(value));
}

const previewState = {
  config: deepClone(defaultPreviewConfig),
  taglines: deepClone(fallbackData.taglines),
  easterEggs: deepClone(fallbackData.easterEggs),
  pages: [],
  selectedPageID: null,
  editor: null,
};

const cardNode = document.querySelector('.preview-card');
const currentBadgeButton = document.getElementById('current-badge-button');
const currentBadgeYearNode = document.getElementById('current-badge-year');
const currentBadgeDateNode = document.getElementById('current-badge-date');
const currentBadgeWeekdayNode = document.getElementById('current-badge-weekday');
const pageSwitcherNode = document.getElementById('page-switcher');
const quotePanelNode = document.getElementById('quote-panel');
const quoteFooterNode = document.getElementById('quote-footer');
const rerollButton = document.getElementById('reroll-button');
const countdownBlock = document.getElementById('countdown-block');
const simDateInput = document.getElementById('sim-date');
const jumpTodayButton = document.getElementById('jump-today');
const shiftButtons = Array.from(document.querySelectorAll('[data-shift-days]'));
const jumpButtons = Array.from(document.querySelectorAll('[data-jump]'));
const taglineCountNode = document.getElementById('tagline-count');
const eggCountNode = document.getElementById('egg-count');
const toneLabelNode = document.getElementById('tone-label');
const simDateLabelNode = document.getElementById('sim-date-label');
const simTargetLabelNode = document.getElementById('sim-target-label');
const sourceStatusNode = document.getElementById('source-status');

const pageEditorNode = document.getElementById('page-editor');
const pageEditorScrim = document.getElementById('page-editor-scrim');
const pageEditorForm = document.getElementById('page-editor-form');
const pageEditorEyebrow = document.getElementById('page-editor-eyebrow');
const pageEditorTitle = document.getElementById('page-editor-title');
const pageEditorClose = document.getElementById('page-editor-close');
const pageTitleInput = document.getElementById('page-title-input');
const pageDateInput = document.getElementById('page-date-input');
const pageDeleteButton = document.getElementById('page-delete-button');
const pageCancelButton = document.getElementById('page-cancel-button');

function cloneDataMap(map) {
  return Object.fromEntries(
    Object.entries(map).map(([name, entries]) => [name, entries.map((lines) => [...lines])]),
  );
}

function sumEntries(map) {
  return Object.values(map).reduce((sum, entries) => sum + entries.length, 0);
}

function toInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function currentDayStart() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function normalizeDate(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function parseDateInput(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;
  return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
}

function formatInputDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function dayStamp(date) {
  return formatInputDate(date);
}

function currentDateCardParts(date) {
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  const year = String(date.getFullYear());
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return {
    year,
    date: `${month}.${day}`,
    weekday: weekdays[date.getDay()],
  };
}

function formatFullDateLabel(date) {
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}.${month}.${day} ${weekdays[date.getDay()]}`;
}

function formatTargetLabel(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}.${month}.${day}`;
}

function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return normalizeDate(result);
}

function makeID() {
  if (window.crypto && typeof window.crypto.randomUUID === 'function') {
    return window.crypto.randomUUID();
  }
  return `page-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
}

function makeDefaultTarget(referenceDate) {
  const year = referenceDate.getFullYear();
  let target = new Date(year, previewState.config.targetMonth - 1, previewState.config.targetDay);
  if (referenceDate > target) {
    target = new Date(year + 1, previewState.config.targetMonth - 1, previewState.config.targetDay);
  }
  return normalizeDate(target);
}

function normalizePage(page, referenceDate = currentDayStart()) {
  const safeTarget = (() => {
    if (page.targetDate instanceof Date) {
      return normalizeDate(page.targetDate);
    }
    if (typeof page.targetDate === 'string') {
      const parsed = parseDateInput(page.targetDate);
      if (parsed) return normalizeDate(parsed);
    }
    return addDays(referenceDate, 30);
  })();

  const title = typeof page.title === 'string' && page.title.trim() ? page.title.trim() : '新的日期';
  const id = typeof page.id === 'string' && page.id ? page.id : makeID();

  return {
    id,
    title,
    targetDate: formatInputDate(safeTarget),
  };
}

function createDefaultPage(referenceDate = currentDayStart()) {
  return normalizePage({
    id: makeID(),
    title: previewState.config.titleLine,
    targetDate: makeDefaultTarget(referenceDate),
  }, referenceDate);
}

function savePages() {
  localStorage.setItem(pagesStorageKey, JSON.stringify(previewState.pages));
  if (previewState.selectedPageID) {
    localStorage.setItem(selectedPageStorageKey, previewState.selectedPageID);
  }
}

function initializePages() {
  let storedPages = [];
  try {
    const raw = localStorage.getItem(pagesStorageKey);
    const parsed = raw ? JSON.parse(raw) : [];
    if (Array.isArray(parsed)) {
      storedPages = parsed.map((page) => normalizePage(page));
    }
  } catch (error) {
    console.warn('Failed to load preview pages', error);
  }

  if (!storedPages.length) {
    storedPages = [createDefaultPage()];
  }

  previewState.pages = storedPages;
  const storedSelected = localStorage.getItem(selectedPageStorageKey);
  previewState.selectedPageID = storedPages.some((page) => page.id === storedSelected)
    ? storedSelected
    : storedPages[0].id;
  savePages();
}

function currentPage() {
  if (!previewState.pages.length) {
    initializePages();
  }
  return previewState.pages.find((page) => page.id === previewState.selectedPageID) || previewState.pages[0];
}

function currentTargetDate() {
  return parseDateInput(currentPage().targetDate) || makeDefaultTarget(currentDayStart());
}

function daysRemaining(today, target) {
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

function toneLabel(tone) {
  switch (tone) {
    case 'today':
      return '主题：当天';
    case 'final':
      return '主题：最后 10 天';
    case 'milestone':
      return '主题：里程碑';
    default:
      return '主题：常规日';
  }
}

function fnv1a32(input) {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

function mulberry32(seed) {
  let value = seed >>> 0;
  return function next() {
    value += 0x6d2b79f5;
    let result = value;
    result = Math.imul(result ^ (result >>> 15), result | 1);
    result ^= result + Math.imul(result ^ (result >>> 7), result | 61);
    return ((result ^ (result >>> 14)) >>> 0) / 4294967296;
  };
}

function makeRng(seedText) {
  return mulberry32(fnv1a32(seedText));
}

function randomInt(rng, min, max) {
  return Math.floor(rng() * (max - min + 1)) + min;
}

function pickWeightedCategory(pool, weights, rng) {
  const buckets = Object.keys(pool)
    .map((name) => ({ name, weight: weights[name] || 0, items: [...pool[name]] }))
    .filter((entry) => entry.weight > 0 && entry.items.length > 0);

  if (!buckets.length) return null;

  const totalWeight = buckets.reduce((sum, entry) => sum + entry.weight, 0);
  let pick = rng() * totalWeight;
  for (const entry of buckets) {
    pick -= entry.weight;
    if (pick < 0) return entry.name;
  }
  return buckets[buckets.length - 1].name;
}

function pickTaglines(seedText) {
  const rng = makeRng(seedText);
  const available = Object.values(previewState.taglines).reduce((sum, items) => sum + items.length, 0);
  const count = Math.min(
    available,
    randomInt(rng, previewState.config.taglineCountMin, previewState.config.taglineCountMax),
  );

  const working = cloneDataMap(previewState.taglines);
  const picked = [];

  while (picked.length < count) {
    const category = pickWeightedCategory(working, previewState.config.taglineWeights, rng);
    if (!category) break;
    const bucket = working[category];
    const index = randomInt(rng, 0, bucket.length - 1);
    picked.push({ lines: bucket.splice(index, 1)[0], egg: false });
  }

  return picked;
}

function easterCondition(name, today, remainingDaysCount) {
  const weekday = today.getDay();
  switch (name) {
    case 'always':
      return true;
    case 'thursday':
      return weekday === 4;
    case 'weekend':
      return weekday === 0 || weekday === 6;
    case 'august':
      return today.getMonth() === 7;
    case 'final30':
      return remainingDaysCount >= 1 && remainingDaysCount <= 30;
    case 'final10':
      return remainingDaysCount >= 1 && remainingDaysCount <= 10;
    case 'milestones':
      return milestoneDays.has(remainingDaysCount);
    case 'cookie':
      return true;
    default:
      return false;
  }
}

function pickEasterEgg(seedText, today, remainingDaysCount) {
  const rng = makeRng(`${seedText}::easter`);
  if (randomInt(rng, 1, 100) > previewState.config.easterEggDailyChance) {
    return null;
  }

  const filtered = Object.fromEntries(
    Object.entries(previewState.easterEggs).filter(([name, entries]) => (
      easterCondition(name, today, remainingDaysCount) && entries.length > 0
    )),
  );

  const category = pickWeightedCategory(filtered, previewState.config.easterWeights, rng);
  if (!category) return null;

  const bucket = filtered[category];
  return { lines: bucket[randomInt(rng, 0, bucket.length - 1)], egg: true };
}

function currentRerollSeed(today) {
  const stamp = dayStamp(today);
  if (localStorage.getItem(rerollDateKey) !== stamp) {
    localStorage.removeItem(rerollStorageKey);
    localStorage.setItem(rerollDateKey, stamp);
  }
  return localStorage.getItem(rerollStorageKey);
}

function saveRerollSeed(today) {
  const stamp = dayStamp(today);
  const token = `${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
  localStorage.setItem(rerollDateKey, stamp);
  localStorage.setItem(rerollStorageKey, token);
}

function resolveTone(days) {
  if (days === 0) return 'today';
  if (days < 0) return 'default';
  if (days <= 10) return 'final';
  if (milestoneDays.has(days)) return 'milestone';
  return 'default';
}

function renderCountdown(days, titleLine) {
  const absolute = Math.abs(days);
  const unit = days < 0 ? '天前' : '天';

  if (days === 0) {
    countdownBlock.innerHTML = `
      <p class="preview-card__title preview-card__title--count">${titleLine}</p>
      <div class="preview-card__countline">
        <span class="preview-card__days">今天</span>
      </div>
      <div class="preview-card__countline">
        <span class="preview-card__unit">就是这一天</span>
      </div>
    `;
    return;
  }

  countdownBlock.innerHTML = `
    <p class="preview-card__title preview-card__title--count">${titleLine}</p>
    <div class="preview-card__countline">
      <span class="preview-card__days">${absolute}</span>
      <span class="preview-card__unit">${unit}</span>
    </div>
  `;
}

function renderPrimaryEntries(entries) {
  quotePanelNode.innerHTML = '';
  entries.forEach((entry) => {
    const isBilingual = entry.lines.length > 1;
    const wrapper = document.createElement('div');
    wrapper.className = `quote-entry${isBilingual ? ' quote-entry--bilingual' : ''}`;

    if (isBilingual) {
      const rail = document.createElement('span');
      rail.className = 'quote-entry__rail';
      wrapper.appendChild(rail);

      const content = document.createElement('div');
      content.className = 'quote-entry__content';

      entry.lines.forEach((line, index) => {
        const paragraph = document.createElement('p');
        paragraph.className = `quote-entry__line quote-entry__line--${index === 0 ? 'lead' : 'follow'}`;
        paragraph.textContent = line;
        content.appendChild(paragraph);
      });

      wrapper.appendChild(content);
    } else {
      entry.lines.forEach((line, index) => {
        const paragraph = document.createElement('p');
        paragraph.className = `quote-entry__line quote-entry__line--${index === 0 ? 'lead' : 'follow'}`;
        paragraph.textContent = line;
        wrapper.appendChild(paragraph);
      });
    }

    quotePanelNode.appendChild(wrapper);
  });
}

function renderEggFooter(entry) {
  quoteFooterNode.innerHTML = '';
  quoteFooterNode.hidden = !entry;
  if (!entry) return;

  const chip = document.createElement('span');
  chip.className = 'quote-chip';
  chip.textContent = entry.lines[0];
  quoteFooterNode.appendChild(chip);
}

function renderPageSwitcher() {
  const activePage = currentPage();
  const activeIndex = Math.max(0, previewState.pages.findIndex((page) => page.id === activePage.id));
  pageSwitcherNode.innerHTML = '';

  const prevButton = document.createElement('button');
  prevButton.className = 'page-switcher__nav';
  prevButton.type = 'button';
  prevButton.title = '上一页';
  prevButton.textContent = '‹';
  prevButton.addEventListener('click', () => {
    const nextIndex = (activeIndex - 1 + previewState.pages.length) % previewState.pages.length;
    previewState.selectedPageID = previewState.pages[nextIndex].id;
    savePages();
    renderCard();
  });
  pageSwitcherNode.appendChild(prevButton);

  const countNode = document.createElement('span');
  countNode.className = 'page-switcher__count';
  countNode.textContent = `${activeIndex + 1} / ${Math.max(previewState.pages.length, 1)}`;
  pageSwitcherNode.appendChild(countNode);

  const nextButton = document.createElement('button');
  nextButton.className = 'page-switcher__nav';
  nextButton.type = 'button';
  nextButton.title = '下一页';
  nextButton.textContent = '›';
  nextButton.addEventListener('click', () => {
    const nextIndex = (activeIndex + 1) % previewState.pages.length;
    previewState.selectedPageID = previewState.pages[nextIndex].id;
    savePages();
    renderCard();
  });
  pageSwitcherNode.appendChild(nextButton);

  const divider = document.createElement('span');
  divider.className = 'page-switcher__divider';
  divider.setAttribute('aria-hidden', 'true');
  pageSwitcherNode.appendChild(divider);

  const addButton = document.createElement('button');
  addButton.className = 'page-switcher__add';
  addButton.type = 'button';
  addButton.title = '新建日期页';
  addButton.textContent = '+';
  addButton.addEventListener('click', () => openEditor(true));
  pageSwitcherNode.appendChild(addButton);
}

function parseEnvText(text) {
  const values = {};
  text.split(/\r?\n/).forEach((rawLine) => {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) return;
    const index = line.indexOf('=');
    if (index === -1) return;
    const key = line.slice(0, index).trim();
    let value = line.slice(index + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  });
  return values;
}

function parseTaglineFile(text, showEnglishFirst) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => {
      if (line.includes('||')) {
        const parts = line.split('||').map((part) => part.trim()).filter(Boolean);
        return showEnglishFirst ? parts : [...parts].reverse();
      }
      return [line];
    });
}

function parseEggFile(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => [line]);
}

async function fetchText(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`${url} -> ${response.status}`);
  }
  return response.text();
}

function applyEnvConfig(env) {
  previewState.config = {
    ...deepClone(defaultPreviewConfig),
    titleLine: env.TITLE_LINE || defaultPreviewConfig.titleLine,
    targetMonth: toInt(env.TARGET_MONTH, defaultPreviewConfig.targetMonth),
    targetDay: toInt(env.TARGET_DAY, defaultPreviewConfig.targetDay),
    taglineCountMin: toInt(env.TAGLINE_COUNT_MIN, defaultPreviewConfig.taglineCountMin),
    taglineCountMax: toInt(env.TAGLINE_COUNT_MAX, defaultPreviewConfig.taglineCountMax),
    easterEggDailyChance: toInt(env.EASTER_EGG_DAILY_CHANCE, defaultPreviewConfig.easterEggDailyChance),
    showEnglishFirst: (env.SHOW_ENGLISH_FIRST ?? '1') !== '0',
    taglineWeights: { ...defaultPreviewConfig.taglineWeights },
    easterWeights: { ...defaultPreviewConfig.easterWeights },
  };

  Object.keys(previewState.config.taglineWeights).forEach((key) => {
    const envKey = `TAGLINE_WEIGHT_${key.toUpperCase()}`;
    previewState.config.taglineWeights[key] = toInt(env[envKey], previewState.config.taglineWeights[key]);
  });

  Object.keys(previewState.config.easterWeights).forEach((key) => {
    const envKey = `EASTER_WEIGHT_${key.toUpperCase()}`;
    previewState.config.easterWeights[key] = toInt(env[envKey], previewState.config.easterWeights[key]);
  });
}

async function loadSourceFiles() {
  const env = parseEnvText(await fetchText('../App/Resources/Defaults/countdown.env.example'));
  applyEnvConfig(env);

  const taglinePairs = await Promise.all(
    sourceManifest.taglines.map(async (name) => {
      const text = await fetchText(`../App/Resources/Defaults/taglines.d/${name}.txt`);
      return [name, parseTaglineFile(text, previewState.config.showEnglishFirst)];
    }),
  );

  const eggPairs = await Promise.all(
    sourceManifest.easterEggs.map(async (name) => {
      const text = await fetchText(`../App/Resources/Defaults/easter_eggs.d/${name}.txt`);
      return [name, parseEggFile(text)];
    }),
  );

  previewState.taglines = Object.fromEntries(taglinePairs);
  previewState.easterEggs = Object.fromEntries(eggPairs);
}

function loadSimulatedDate() {
  const stored = localStorage.getItem(simulatedDateStorageKey);
  if (stored) {
    const parsed = parseDateInput(stored);
    if (parsed) return normalizeDate(parsed);
  }
  return currentDayStart();
}

function saveSimulatedDate(date) {
  localStorage.setItem(simulatedDateStorageKey, formatInputDate(date));
}

function updateMetaCounters() {
  taglineCountNode.textContent = `${sumEntries(previewState.taglines)} 条副标题`;
  eggCountNode.textContent = `${sumEntries(previewState.easterEggs)} 条小彩蛋`;
}

function syncJumpButtons(today, target) {
  const quickTargets = {
    target,
    minus30: addDays(target, -30),
    minus10: addDays(target, -10),
    'month-start': new Date(target.getFullYear(), target.getMonth(), 1),
  };

  jumpButtons.forEach((button) => {
    const jump = button.dataset.jump;
    const targetDate = jump ? quickTargets[jump] : null;
    const active = targetDate && dayStamp(targetDate) === dayStamp(today);
    button.classList.toggle('is-active', Boolean(active));
  });
}

function renderCard() {
  const today = loadSimulatedDate();
  const page = currentPage();
  const target = currentTargetDate();
  const remainingDaysCount = daysRemaining(today, target);
  const seedBase = `${dayStamp(today)}::${page.id}`;
  const rerollSeed = currentRerollSeed(today);
  const seedText = rerollSeed ? `${seedBase}::${rerollSeed}` : seedBase;
  const entries = pickTaglines(seedText);
  const egg = pickEasterEgg(seedText, today, remainingDaysCount);
  const tone = resolveTone(remainingDaysCount);
  const badgeParts = currentDateCardParts(today);

  cardNode.dataset.tone = tone;
  currentBadgeYearNode.textContent = badgeParts.year;
  currentBadgeDateNode.textContent = badgeParts.date;
  currentBadgeWeekdayNode.textContent = badgeParts.weekday;
  simDateInput.value = formatInputDate(today);
  simDateLabelNode.textContent = `模拟日期：${formatFullDateLabel(today)}`;
  simTargetLabelNode.textContent = `当前页：${page.title} · ${formatTargetLabel(target)}`;
  toneLabelNode.textContent = toneLabel(tone);

  syncJumpButtons(today, target);
  renderCountdown(remainingDaysCount, page.title);
  renderPrimaryEntries(entries);
  renderEggFooter(egg);
  renderPageSwitcher();
}

function jumpToPreset(kind) {
  const target = currentTargetDate();

  switch (kind) {
    case 'target':
      saveSimulatedDate(target);
      break;
    case 'minus30':
      saveSimulatedDate(addDays(target, -30));
      break;
    case 'minus10':
      saveSimulatedDate(addDays(target, -10));
      break;
    case 'month-start':
      saveSimulatedDate(new Date(target.getFullYear(), target.getMonth(), 1));
      break;
    default:
      return;
  }

  renderCard();
}

function openEditor(isNew) {
  const page = currentPage();
  const baseDate = parseDateInput(page.targetDate) || currentDayStart();
  previewState.editor = isNew
    ? {
        isNew: true,
        sourcePageID: null,
        title: '新的日期',
        targetDate: formatInputDate(addDays(baseDate, 30)),
      }
    : {
        isNew: false,
        sourcePageID: page.id,
        title: page.title,
        targetDate: page.targetDate,
      };

  pageEditorEyebrow.textContent = isNew ? '新建倒计时页' : '编辑当前倒计时';
  pageEditorTitle.textContent = isNew ? '给新的日期页起个名字' : '双击标题或日期牌都能打开这里';
  pageTitleInput.value = previewState.editor.title;
  pageDateInput.value = previewState.editor.targetDate;
  pageDeleteButton.hidden = isNew || previewState.pages.length <= 1;
  pageEditorNode.hidden = false;
  pageTitleInput.focus();
  pageTitleInput.select();
}

function closeEditor() {
  previewState.editor = null;
  pageEditorNode.hidden = true;
}

function saveEditor() {
  if (!previewState.editor) return;

  const draftTitle = pageTitleInput.value.trim() || '新的日期';
  const draftDate = parseDateInput(pageDateInput.value) || addDays(currentTargetDate(), 30);
  const page = normalizePage({
    id: previewState.editor.sourcePageID || makeID(),
    title: draftTitle,
    targetDate: draftDate,
  });

  if (previewState.editor.isNew) {
    const currentIndex = previewState.pages.findIndex((entry) => entry.id === previewState.selectedPageID);
    const insertionIndex = currentIndex === -1 ? previewState.pages.length : currentIndex + 1;
    previewState.pages.splice(insertionIndex, 0, page);
  } else {
    const index = previewState.pages.findIndex((entry) => entry.id === page.id);
    if (index !== -1) {
      previewState.pages.splice(index, 1, page);
    }
  }

  previewState.selectedPageID = page.id;
  savePages();
  closeEditor();
  renderCard();
}

function deleteCurrentPage() {
  if (previewState.pages.length <= 1) return;
  const index = previewState.pages.findIndex((page) => page.id === previewState.selectedPageID);
  if (index === -1) return;

  previewState.pages.splice(index, 1);
  const fallbackIndex = Math.min(index, previewState.pages.length - 1);
  previewState.selectedPageID = previewState.pages[fallbackIndex].id;
  savePages();
  closeEditor();
  renderCard();
}

function bindInteractions() {
  rerollButton.addEventListener('click', () => {
    const today = loadSimulatedDate();
    saveRerollSeed(today);
    renderCard();
  });

  currentBadgeButton.addEventListener('dblclick', () => {
    openEditor(false);
  });

  countdownBlock.addEventListener('dblclick', () => {
    openEditor(false);
  });

  jumpTodayButton.addEventListener('click', () => {
    const today = currentDayStart();
    saveSimulatedDate(today);
    renderCard();
  });

  simDateInput.addEventListener('change', (event) => {
    const nextDate = parseDateInput(event.target.value);
    if (!nextDate) return;
    saveSimulatedDate(nextDate);
    renderCard();
  });

  shiftButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const current = loadSimulatedDate();
      const delta = toInt(button.dataset.shiftDays, 0);
      saveSimulatedDate(addDays(current, delta));
      renderCard();
    });
  });

  jumpButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const kind = button.dataset.jump;
      if (kind) jumpToPreset(kind);
    });
  });

  pageEditorScrim.addEventListener('click', closeEditor);
  pageEditorClose.addEventListener('click', closeEditor);
  pageCancelButton.addEventListener('click', closeEditor);
  pageDeleteButton.addEventListener('click', deleteCurrentPage);
  pageEditorForm.addEventListener('submit', (event) => {
    event.preventDefault();
    saveEditor();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !pageEditorNode.hidden) {
      closeEditor();
    }
  });
}

async function init() {
  initializePages();
  bindInteractions();
  updateMetaCounters();
  renderCard();

  try {
    await loadSourceFiles();
    updateMetaCounters();
    if (!localStorage.getItem(pagesStorageKey)) {
      initializePages();
    }
    sourceStatusNode.textContent = '已读取仓库中的真实文案库和权重。双击标题或日期牌可编辑当前倒计时，点右侧圆点切页。';
  } catch (error) {
    console.error(error);
    sourceStatusNode.textContent = '未能读取仓库源文件。请在仓库根目录运行 python3 -m http.server 8000 后再打开预览。';
  }

  renderCard();
}

init();
