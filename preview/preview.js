const previewConfig = {
  titleLine: "距离 8.31",
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
    friday: 2,
    weekend: 2,
    august: 3,
    final30: 4,
    final10: 6,
    milestones: 6,
    cookie: 3,
  },
};

const taglines = {
  bright: [
    ["你今天是最棒的！"],
    ["真棒！"],
    ["今天也会顺顺利利"],
    ["今天也要开开心心"],
    ["今天大家都爱你~"],
    ["今天也值得被夸夸"],
    ["今天也请喜欢自己一点"],
    ["今天会有好事发生"],
    ["离 8.31 又近一点啦"],
    ["离那一天更近一点啦"],
    ["好，继续出发！"],
    ["今天状态不错哦"],
    ["今天也闪闪发亮"],
    ["你今天真的很棒"],
    ["给今天的自己鼓鼓掌"],
    ["今天先对自己好一点"],
    ["今天记得抬头挺胸"],
    ["别急，你已经很好了"],
    ["慢慢来也没关系"],
    ["好心情正在靠近你"],
    ["今天也会被温柔接住"],
    ["今天是可爱的一天"],
    ["今天一定有一点点幸运"],
    ["你值得很多很多偏爱"],
    ["今天大家都站你这边"],
    ["先完成一点点，也很棒"],
    ["你已经比昨天更近了"],
    ["8 月 31 日在等你"],
    ["期待正在慢慢变近"],
  ],
  cookie: [
    ["cookie是世界上最好的猫！"],
    ["Cookie 觉得你今天超棒"],
    ["Cookie 说你已经很厉害了"],
    ["Cookie 路过，顺手夸夸你"],
    ["想到 Cookie 心情就变好了"],
    ["Cookie 今天也支持你"],
    ["Cookie 认证：今天也很可以"],
    ["Cookie 远程给你踩奶成功"],
    ["Cookie 说先开心一下"],
    ["Cookie 觉得你值得被偏爱"],
    ["Cookie 陪你一起等 8.31"],
    ["Cookie 说今天适合吸一口猫"],
    ["Cookie 觉得世界纷纷扰扰，但你很重要"],
    ["Cookie 说先摸摸小猫再出发"],
    ["出门前请咬 Cookie 一口"],
    ["Cookie 已经在门口给你送行了"],
    ["Cookie 觉得今天可以先从贴贴开始"],
    ["Cookie 觉得你今天不许委屈"],
  ],
  playful: [
    ["啊啊啊啊啊啊啊啊"],
    ["（尖叫发泄）"],
    ["上号搞饥吗？"],
    ["今天要不要偷偷喝点？"],
    ["缺爱吗，姐姐？今天不缺"],
    ["今天适合小小发疯一下"],
    ["今天先尖叫两声再出门"],
    ["今天先别讲道理"],
    ["今天允许一点点荒诞"],
    ["上号吗，今天适合联机活命"],
  ],
  reminders: [
    ["今天要运动！"],
    ["今天记得喝水！"],
    ["今天记得按时吃饭"],
    ["吃药了吗？"],
    ["今天也别忘了休息"],
    ["起身活动一下吧"],
    ["去晒晒太阳也不错"],
    ["别久坐太久哦"],
    ["今天也要照顾好自己"],
    ["睡前记得放松一下"],
    ["记得伸个懒腰"],
    ["给自己留一点喘气时间"],
  ],
  wendy: [
    ["Everything dies.", "万物皆有一死。"],
    ["Nothing comes of nothing.", "无中生无。"],
    ["Will you leave too?", "你也要离开我？"],
    ["Freedom. Great.", "自由，太好了。"],
    ["The darkness has swallowed me.", "黑暗吞没了我。"],
    ["And there was light!", "随后就有了光！"],
    ["Smells like death.", "闻起来像死亡的味道。"],
    ["Not all deaths are alike.", "并不是所有死亡都是相似的。"],
    ["My heart is heavy enough... without this...", "我内心已经极其沉重了...怎么还来这个..."],
    ["Abigail? Was that you...?", "阿比盖尔？是你吗……？"],
    ["I can see a light...", "我看见一束光……"],
    ["I have seen the void and it is deep and dark.", "我看到了虚空，它深沉而又黑暗。"],
    ["Abigail has always been my guiding light in the darkness...", "阿比盖尔一直是我黑暗中的指路明灯……"],
    ["A wretched hive of scum and pollen.", "充满渣滓和花粉的可悲蜂窝。"],
    ["The ground shakes. Will it swallow me whole?", "大地在晃动。它会将我整个吞没吗？"],
  ],
};

const easterEggs = {
  always: [
    ["隐藏彩蛋：今天适合奖励自己一下"],
    ["隐藏彩蛋：请收下今天的小幸运"],
    ["隐藏彩蛋：已经在悄悄靠近好事了"],
  ],
  august: [
    ["8 月到了，真的越来越近了"],
    ["这个月就是 8.31 的月份"],
  ],
  cookie: [
    ["隐藏彩蛋：Cookie 正在认真爱你"],
    ["隐藏彩蛋：Cookie 批准今天有好心情"],
    ["隐藏彩蛋：Cookie 觉得你值得一个罐头级夸奖"],
  ],
  final10: [
    ["个位数倒计时就在前面了"],
    ["最后 10 天，心跳会快一点"],
  ],
  final30: [
    ["30 天内冲刺模式启动"],
    ["已经进入最后一个月的范围啦"],
  ],
  friday: [
    ["周五加成已生效"],
    ["今天带一点周五滤镜"],
  ],
  milestones: [
    ["今天是一个很好记的里程碑"],
    ["这种整数倒计时，值得多看一眼"],
  ],
  weekend: [
    ["周末了，记得松一口气"],
    ["今天适合把步子放慢一点"],
  ],
};

const titleNode = document.getElementById("card-title");
const quotePanelNode = document.getElementById("quote-panel");
const rerollButton = document.getElementById("reroll-button");
const countdownBlock = document.getElementById("countdown-block");

const rerollStorageKey = "abigail-flower-preview-reroll-seed";
const rerollDateKey = "abigail-flower-preview-reroll-date";

function dayStamp(date) {
  return date.toISOString().slice(0, 10);
}

function currentDayStart() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function makeTarget(today) {
  const year = today.getFullYear();
  let target = new Date(year, previewConfig.targetMonth - 1, previewConfig.targetDay);
  if (today > target) {
    target = new Date(year + 1, previewConfig.targetMonth - 1, previewConfig.targetDay);
  }
  return target;
}

function daysRemaining(today, target) {
  const delta = target.getTime() - today.getTime();
  return Math.round(delta / 86400000);
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
  let t = seed >>> 0;
  return function next() {
    t += 0x6d2b79f5;
    let x = t;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

function makeRng(seedText) {
  return mulberry32(fnv1a32(seedText));
}

function randomInt(rng, min, max) {
  return Math.floor(rng() * (max - min + 1)) + min;
}

function pickWeightedCategory(pool, weights, rng) {
  const entries = Object.keys(pool)
    .map((name) => ({ name, weight: weights[name] || 0, items: [...pool[name]] }))
    .filter((entry) => entry.weight > 0 && entry.items.length > 0);

  if (!entries.length) return null;

  const totalWeight = entries.reduce((sum, entry) => sum + entry.weight, 0);
  let pick = rng() * totalWeight;
  for (const entry of entries) {
    pick -= entry.weight;
    if (pick < 0) return entry.name;
  }
  return entries[entries.length - 1].name;
}

function pickTaglines(seedText) {
  const rng = makeRng(seedText);
  const available = Object.values(taglines).reduce((sum, items) => sum + items.length, 0);
  const count = Math.min(
    available,
    randomInt(rng, previewConfig.taglineCountMin, previewConfig.taglineCountMax),
  );

  const working = Object.fromEntries(
    Object.entries(taglines).map(([name, items]) => [name, [...items]]),
  );

  const picked = [];
  while (picked.length < count) {
    const category = pickWeightedCategory(working, previewConfig.taglineWeights, rng);
    if (!category) break;
    const bucket = working[category];
    const index = randomInt(rng, 0, bucket.length - 1);
    picked.push({ lines: bucket.splice(index, 1)[0], egg: false });
  }

  return { rng, picked };
}

function easterCondition(name, today, remainingDays) {
  const weekday = today.getDay();
  switch (name) {
    case "always":
      return true;
    case "friday":
      return weekday === 5;
    case "weekend":
      return weekday === 0 || weekday === 6;
    case "august":
      return today.getMonth() === 7;
    case "final30":
      return remainingDays >= 1 && remainingDays <= 30;
    case "final10":
      return remainingDays >= 1 && remainingDays <= 10;
    case "milestones":
      return [200, 160, 150, 120, 100, 60, 50, 30, 10, 7, 3, 1].includes(remainingDays);
    case "cookie":
      return true;
    default:
      return false;
  }
}

function pickEasterEgg(seedText, today, remainingDays) {
  const rng = makeRng(`${seedText}::easter`);
  if (randomInt(rng, 1, 100) > previewConfig.easterEggDailyChance) {
    return null;
  }

  const filtered = Object.fromEntries(
    Object.entries(easterEggs).filter(([name, entries]) => (
      easterCondition(name, today, remainingDays) && entries.length > 0
    )),
  );

  const category = pickWeightedCategory(filtered, previewConfig.easterWeights, rng);
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

function renderEntries(entries) {
  quotePanelNode.innerHTML = "";
  entries.forEach((entry) => {
    const wrapper = document.createElement("div");
    wrapper.className = `quote-entry${entry.lines.length > 1 ? " quote-entry--bilingual" : ""}${entry.egg ? " quote-entry--egg" : ""}`;

    entry.lines.forEach((line, index) => {
      const p = document.createElement("p");
      p.className = `quote-entry__line quote-entry__line--${index === 0 ? "lead" : "follow"}`;
      p.textContent = line;
      wrapper.appendChild(p);
    });

    quotePanelNode.appendChild(wrapper);
  });
}

function renderCard() {
  const today = currentDayStart();
  const target = makeTarget(today);
  const remainingDays = daysRemaining(today, target);
  const seedBase = `${dayStamp(today)}::${previewConfig.titleLine}`;
  const rerollSeed = currentRerollSeed(today);
  const seedText = rerollSeed ? `${seedBase}::${rerollSeed}` : seedBase;

  titleNode.textContent = previewConfig.titleLine;

  if (remainingDays === 0) {
    countdownBlock.innerHTML = `
      <div class="preview-card__countline">
        <span class="preview-card__days">今天</span>
      </div>
      <div class="preview-card__countline">
        <span class="preview-card__unit">就是 8.31</span>
      </div>
    `;
  } else {
    countdownBlock.innerHTML = `
      <div class="preview-card__countline">
        <span class="preview-card__days">${remainingDays}</span>
        <span class="preview-card__unit">天</span>
      </div>
    `;
  }

  const { picked } = pickTaglines(seedText);
  const egg = pickEasterEgg(seedText, today, remainingDays);
  const entries = egg ? [...picked, egg] : picked;
  renderEntries(entries);
}

rerollButton.addEventListener("click", () => {
  const today = currentDayStart();
  saveRerollSeed(today);
  renderCard();
});

renderCard();
